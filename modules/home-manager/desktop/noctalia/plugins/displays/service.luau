--!nonstrict
-- state channel (service -> ui):
--   outputs = { list, count, enabled, state = "loading"|"success"|"error", error }
--     list[i] = { name, make, model, serial, enabled, currentMode,
--                 modes = { { key, width, height, refresh, preferred } },
--                 scale, x, y, transform }
--   revert  = { pending, secondsLeft }
--   kanshi  = { enabled, available, active, profiles = { { name, managed } } }
--   mirror  = { available, active, source, destination, error }
--   hotplug = number (nonce, bumped when output/enabled count changes)
-- state channel (ui -> service):
--   command = { action, ..., nonce }

local REVERT_SECONDS = 12

local pollMs = 5000
local kanshiEnabled = true
local kanshiDirOverride = ""

local function loadConfig()
  local secs = tonumber(noctalia.getConfig("poll_interval")) or 5
  pollMs = math.max(2, secs) * 1000
  kanshiEnabled = noctalia.getConfig("kanshi_enabled") ~= false
  local dir = noctalia.getConfig("kanshi_config_dir")
  kanshiDirOverride = type(dir) == "string" and dir or ""
end

local outputs = {}
local outputCount = 0
local enabledCount = 0
local lastOutputCount = -1
local lastEnabledCount = -1
local fetchState = "loading"
local fetchError = ""
local fetching = false
local hotplugNonce = 0

local revert = { pending = false, secondsLeft = 0, snapshot = nil }

local kanshi = { available = false, active = "", profiles = {} }

local mirror = {
  available = noctalia.commandExists("wl-mirror"),
  active = false,
  source = "",
  destination = "",
  error = "",
  stopping = false,
}

local fetchOutputs -- forward: pump() refetches after a drained queue

local function shellQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function publishOutputs()
  noctalia.state.set("outputs", {
    list = outputs,
    count = outputCount,
    enabled = enabledCount,
    state = fetchState,
    error = fetchError,
  })
end

local function publishRevert()
  noctalia.state.set("revert", { pending = revert.pending, secondsLeft = revert.secondsLeft })
end

local function publishKanshi()
  noctalia.state.set("kanshi", {
    enabled = kanshiEnabled,
    available = kanshi.available,
    active = kanshi.active,
    profiles = kanshi.profiles,
  })
end

local function publishMirror()
  noctalia.state.set("mirror", {
    available = mirror.available,
    active = mirror.active,
    source = mirror.source,
    destination = mirror.destination,
    error = mirror.error,
  })
end

-- niri msg calls must run sequentially; re-query once the queue drains.
local queue = {}
local applying = false

local function pump()
  if applying then
    return
  end
  local cmd = table.remove(queue, 1)
  if cmd == nil then
    fetchOutputs()
    return
  end
  applying = true
  noctalia.runAsync(cmd, function(res)
    applying = false
    if res.exitCode ~= 0 then
      noctalia.log("displays: apply failed: " .. cmd .. ": " .. noctalia.string.trim(res.stderr or ""))
    end
    pump()
  end, 10000)
end

local function enqueue(cmds)
  for _, c in ipairs(cmds) do
    table.insert(queue, c)
  end
  pump()
end

-- opts: { enabled, mode, scale, x, y, transform }
local function niriOutputCmds(name, opts)
  local q = shellQuote(name)
  local cmds = {}
  if opts.enabled == false then
    table.insert(cmds, "niri msg output " .. q .. " off")
    return cmds
  end
  if opts.enabled == true then
    table.insert(cmds, "niri msg output " .. q .. " on")
  end
  if opts.mode then
    table.insert(cmds, "niri msg output " .. q .. " mode " .. shellQuote(opts.mode))
  end
  if opts.scale then
    table.insert(cmds, "niri msg output " .. q .. " scale " .. tostring(opts.scale))
  end
  if opts.x ~= nil and opts.y ~= nil then
    table.insert(cmds, "niri msg output " .. q .. " position set " .. tostring(opts.x) .. " " .. tostring(opts.y))
  end
  if opts.transform then
    table.insert(cmds, "niri msg output " .. q .. " transform " .. shellQuote(opts.transform))
  end
  return cmds
end

local function takeSnapshot()
  local snap = {}
  for _, o in ipairs(outputs) do
    table.insert(snap, {
      name = o.name,
      enabled = o.enabled,
      mode = o.currentMode,
      scale = o.scale,
      x = o.x,
      y = o.y,
      transform = o.transform,
    })
  end
  return snap
end

local function armRevert()
  -- Keep the earliest snapshot across a burst of changes so revert restores
  -- the state before the user started editing.
  if not revert.pending or revert.snapshot == nil then
    revert.snapshot = takeSnapshot()
  end
  revert.pending = true
  revert.secondsLeft = REVERT_SECONDS
  publishRevert()
  noctalia.setUpdateInterval(1000)
  noctalia.notify("Display changed", "Reverting in " .. REVERT_SECONDS .. "s unless confirmed from the panel")
end

local function clearRevert()
  revert.pending = false
  revert.snapshot = nil
  revert.secondsLeft = 0
  publishRevert()
  noctalia.setUpdateInterval(pollMs)
end

local function confirmRevert()
  if not revert.pending then
    return
  end
  clearRevert()
end

local function applySnapshot(snap)
  local cmds = {}
  for _, o in ipairs(snap) do
    local opts
    if o.enabled == false then
      opts = { enabled = false }
    else
      opts = { enabled = true, mode = o.mode, scale = o.scale, x = o.x, y = o.y, transform = o.transform }
    end
    for _, c in ipairs(niriOutputCmds(o.name, opts)) do
      table.insert(cmds, c)
    end
  end
  enqueue(cmds)
end

local function doRevert()
  local snap = revert.snapshot
  clearRevert()
  if snap ~= nil then
    applySnapshot(snap)
    noctalia.notify("Display reverted", "Change was not confirmed")
  end
end

-- opts as niriOutputCmds; withRevert arms the countdown first
local function applyOutput(name, opts, withRevert)
  if withRevert then
    armRevert()
  end
  enqueue(niriOutputCmds(name, opts))
end

local function currentModeOf(o)
  for _, m in ipairs(o.modes) do
    if m.key == o.currentMode then
      return m
    end
  end
  for _, m in ipairs(o.modes) do
    if m.preferred then
      return m
    end
  end
  return o.modes[1]
end

local function logicalSize(o)
  local m = currentModeOf(o)
  if m == nil then
    return { w = 1920, h = 1080 }
  end
  local s = o.scale or 1.0
  local rot = o.transform == "90"
    or o.transform == "270"
    or o.transform == "flipped-90"
    or o.transform == "flipped-270"
  local w = rot and m.height or m.width
  local h = rot and m.width or m.height
  return { w = math.floor(w / s + 0.5), h = math.floor(h / s + 0.5) }
end

local function isInternal(o)
  local n = o.name:lower()
  return n:match("^edp") ~= nil or n:match("^lvds") ~= nil or n:match("^dsi") ~= nil
end

local function splitLaptopExternal()
  local laptop, external
  for _, o in ipairs(outputs) do
    if isInternal(o) then
      laptop = o
    else
      external = o
    end
  end
  if laptop == nil or external == nil then
    laptop = outputs[1]
    external = outputs[2]
  end
  return laptop, external
end

-- niri "position set" takes logical px, hence logicalSize.
local function applyArrangement(kind)
  if #outputs ~= 2 then
    noctalia.notifyError("Displays", "Arrangements need exactly 2 outputs (have " .. #outputs .. ")")
    return
  end
  local laptop, external = splitLaptopExternal()
  local laptopSize, externalSize = logicalSize(laptop), logicalSize(external)
  local cmds = {}
  local function on(name)
    table.insert(cmds, "niri msg output " .. shellQuote(name) .. " on")
  end
  local function off(name)
    table.insert(cmds, "niri msg output " .. shellQuote(name) .. " off")
  end
  local function pos(name, x, y)
    table.insert(cmds, "niri msg output " .. shellQuote(name) .. " position set " .. x .. " " .. y)
  end

  if kind == "extend-right" then
    on(laptop.name)
    on(external.name)
    pos(laptop.name, 0, 0)
    pos(external.name, laptopSize.w, 0)
  elseif kind == "extend-left" then
    on(laptop.name)
    on(external.name)
    pos(external.name, 0, 0)
    pos(laptop.name, externalSize.w, 0)
  elseif kind == "stack-above" then
    on(laptop.name)
    on(external.name)
    pos(external.name, 0, 0)
    pos(laptop.name, math.max(0, math.floor((externalSize.w - laptopSize.w) / 2 + 0.5)), externalSize.h)
  elseif kind == "stack-below" then
    on(laptop.name)
    on(external.name)
    pos(laptop.name, 0, 0)
    pos(external.name, math.max(0, math.floor((laptopSize.w - externalSize.w) / 2 + 0.5)), laptopSize.h)
  elseif kind == "external-only" then
    off(laptop.name)
    on(external.name)
    pos(external.name, 0, 0)
  elseif kind == "internal-only" then
    on(laptop.name)
    off(external.name)
    pos(laptop.name, 0, 0)
  else
    noctalia.log("displays: unknown arrangement: " .. tostring(kind))
    return
  end

  armRevert()
  enqueue(cmds)
end

local TRANSFORM_MAP = {
  Normal = "normal",
  ["90"] = "90",
  ["180"] = "180",
  ["270"] = "270",
  Flipped = "flipped",
  Flipped90 = "flipped-90",
  Flipped180 = "flipped-180",
  Flipped270 = "flipped-270",
}

local function formatHz(refreshRateMillihz)
  local hz = string.format("%.3f", refreshRateMillihz / 1000)
  hz = hz:gsub("0+$", ""):gsub("%.$", "")
  return hz
end

local function normalizeNiri(json)
  local list = {}
  for name, o in pairs(json) do
    local modes = {}
    if type(o.modes) == "table" then
      for _, m in ipairs(o.modes) do
        table.insert(modes, {
          key = m.width .. "x" .. m.height .. "@" .. formatHz(m.refresh_rate),
          width = m.width,
          height = m.height,
          refresh = m.refresh_rate / 1000,
          preferred = m.is_preferred == true,
        })
      end
    end

    -- current_mode indexes the unsorted modes array (0-based)
    local currentMode = nil
    if o.current_mode ~= nil and type(o.modes) == "table" then
      local cm = o.modes[o.current_mode + 1]
      if cm ~= nil then
        currentMode = cm.width .. "x" .. cm.height .. "@" .. formatHz(cm.refresh_rate)
      end
    end

    table.sort(modes, function(x, y)
      local rx, ry = x.width * x.height, y.width * y.height
      if rx ~= ry then
        return rx > ry
      end
      return x.refresh > y.refresh
    end)

    -- niri JSON uses serde variant names; the CLI wants lowercase kebab-case
    local transform = "normal"
    if o.logical ~= nil and o.logical.transform ~= nil then
      local t = tostring(o.logical.transform)
      transform = TRANSFORM_MAP[t] or t:lower()
    end

    table.insert(list, {
      name = name,
      make = o.make or "",
      model = o.model or "",
      serial = o.serial or "",
      enabled = currentMode ~= nil,
      currentMode = currentMode,
      modes = modes,
      scale = o.logical ~= nil and o.logical.scale or 1.0,
      x = o.logical ~= nil and o.logical.x or 0,
      y = o.logical ~= nil and o.logical.y or 0,
      transform = transform,
    })
  end
  table.sort(list, function(x, y)
    return x.name < y.name
  end)
  return list
end

fetchOutputs = function()
  if fetching then
    return
  end
  fetching = true
  noctalia.runAsync("niri msg -j outputs", function(res)
    fetching = false
    if res.exitCode ~= 0 then
      fetchState = "error"
      fetchError = noctalia.string.trim(res.stderr ~= "" and res.stderr or ("niri msg exited " .. res.exitCode))
      publishOutputs()
      return
    end
    local json, err = noctalia.json.decode(res.stdout)
    if json == nil then
      fetchState = "error"
      fetchError = "parse error: " .. tostring(err)
      publishOutputs()
      return
    end

    outputs = normalizeNiri(json)
    outputCount = #outputs
    enabledCount = 0
    for _, o in ipairs(outputs) do
      if o.enabled then
        enabledCount += 1
      end
    end

    -- A freshly-plugged monitor often appears disabled (no mode yet), so
    -- watch both counts to catch plug and unplug events.
    if lastOutputCount ~= -1 and (lastOutputCount ~= outputCount or lastEnabledCount ~= enabledCount) then
      hotplugNonce += 1
      noctalia.state.set("hotplug", hotplugNonce)
    end
    lastOutputCount = outputCount
    lastEnabledCount = enabledCount

    fetchState = "success"
    fetchError = ""
    publishOutputs()
  end, 10000)
end

-- Profiles we manage live in noctalia.conf; the user's kanshi config is read-only.
local function kanshiDir()
  if kanshiDirOverride ~= "" then
    return noctalia.expandPath(kanshiDirOverride)
  end
  local xdg = noctalia.getenv("XDG_CONFIG_HOME")
  if xdg ~= nil and xdg ~= "" then
    return xdg .. "/kanshi"
  end
  return (noctalia.getenv("HOME") or "") .. "/.config/kanshi"
end

local function managedPath()
  return kanshiDir() .. "/noctalia.conf"
end

local function parseProfiles()
  local seen = {}
  local profiles = {}
  local function add(text, managed)
    if type(text) ~= "string" then
      return
    end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
      local name = line:match("^%s*profile%s+([^%s{]+)")
      if name ~= nil and not seen[name] then
        seen[name] = true
        table.insert(profiles, { name = name, managed = managed })
      end
    end
  end
  add(noctalia.readFile(managedPath()), true)
  add(noctalia.readFile(kanshiDir() .. "/config"), false)
  kanshi.profiles = profiles
end

local function kanshiRefresh()
  if not kanshiEnabled or not noctalia.commandExists("kanshictl") then
    kanshi.available = false
    publishKanshi()
    return
  end
  parseProfiles()
  noctalia.runAsync("kanshictl status", function(res)
    kanshi.available = res.exitCode == 0
    if kanshi.available then
      local json = noctalia.json.decode(res.stdout)
      kanshi.active = type(json) == "table" and json.current_profile or ""
    else
      kanshi.active = ""
    end
    publishKanshi()
  end, 5000)
end

local function kanshiReload()
  noctalia.runAsync("kanshictl reload", function(res)
    if res.exitCode ~= 0 then
      noctalia.notifyError("Kanshi", noctalia.string.trim(res.stderr ~= "" and res.stderr or "kanshictl reload failed"))
    end
    fetchOutputs()
    kanshiRefresh()
  end, 5000)
end

local function switchProfile(name)
  noctalia.runAsync("kanshictl switch " .. shellQuote(name), function(res)
    if res.exitCode ~= 0 then
      noctalia.notifyError("Kanshi", noctalia.string.trim(res.stderr ~= "" and res.stderr or "kanshictl switch failed"))
    end
    fetchOutputs()
    kanshiRefresh()
  end, 5000)
end

-- External monitors with a serial match by "make model serial" (stable across
-- docks); internal panels and serial-less outputs use the connector name.
local function renderProfile(name)
  local lines = { "profile " .. name .. " {" }
  for _, o in ipairs(outputs) do
    local internal = isInternal(o)
    local crit
    if not internal and o.serial ~= "" then
      local make = o.make ~= "" and o.make or "Unknown"
      local model = o.model ~= "" and o.model or "Unknown"
      crit = '"' .. make .. " " .. model .. " " .. o.serial .. '"'
    else
      crit = o.name
    end
    local parts = { "  output", crit }
    if not o.enabled then
      table.insert(parts, "disable")
    else
      table.insert(parts, "enable")
      if o.currentMode ~= nil then
        table.insert(parts, "mode " .. o.currentMode)
      end
      table.insert(parts, "position " .. o.x .. "," .. o.y)
      if o.scale ~= nil then
        table.insert(parts, "scale " .. o.scale)
      end
      if o.transform ~= nil and o.transform ~= "normal" then
        table.insert(parts, "transform " .. o.transform)
      end
    end
    table.insert(lines, table.concat(parts, " "))
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

local function escapePattern(s)
  return s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

-- The managed file only contains blocks we wrote (no nested braces), so a
-- non-greedy match to the next closing brace is a safe parser.
local function withoutProfile(text, name)
  return text:gsub("profile%s+" .. escapePattern(name) .. "%s*{.-\n}\n?", "")
end

local function saveProfile(name)
  name = noctalia.string.trim(tostring(name or ""))
  if not name:match("^[%w_.+-]+$") then
    noctalia.notifyError("Kanshi", "Invalid profile name (use letters, digits, . _ + -)")
    return
  end
  if #outputs == 0 then
    return
  end
  noctalia.mkdirAll(kanshiDir())
  local text = noctalia.readFile(managedPath()) or ""
  local ok, err = noctalia.writeFile(managedPath(), withoutProfile(text, name) .. renderProfile(name))
  if not ok then
    noctalia.notifyError("Kanshi", "Failed to write " .. managedPath() .. ": " .. tostring(err))
    return
  end
  noctalia.notify("Kanshi", "Saved profile '" .. name .. "'")
  kanshiReload()
end

local function deleteProfile(name)
  local text = noctalia.readFile(managedPath())
  if type(text) ~= "string" then
    return
  end
  local ok, err = noctalia.writeFile(managedPath(), withoutProfile(text, name))
  if not ok then
    noctalia.notifyError("Kanshi", "Failed to write " .. managedPath() .. ": " .. tostring(err))
    return
  end
  kanshiReload()
end

local MIRROR_NEEDLE = "wl-mirror --fullscreen-output"

local function startMirror(source, destination)
  if not mirror.available then
    mirror.error = "wl-mirror is not installed"
    publishMirror()
    return
  end
  if mirror.active then
    mirror.error = "Already mirroring"
    publishMirror()
    return
  end
  if source == nil or source == "" or destination == nil or destination == "" then
    mirror.error = "Select source and destination"
    publishMirror()
    return
  end
  if source == destination then
    mirror.error = "Source and destination must differ"
    publishMirror()
    return
  end
  mirror.error = ""
  -- detached (no callback): runAsync callbacks die at the 60s cap, and the
  -- mirror must survive noctalia restarts; stopped via pkill on MIRROR_NEEDLE.
  noctalia.runAsync("wl-mirror --fullscreen-output " .. shellQuote(destination) .. " " .. shellQuote(source))
  mirror.active = true
  mirror.source = source
  mirror.destination = destination
  publishMirror()
end

local function stopMirror()
  if not mirror.active then
    return
  end
  mirror.stopping = true
  noctalia.runAsync("pkill -f " .. shellQuote(MIRROR_NEEDLE), function(_)
    mirror.stopping = false
  end, 5000)
  mirror.active = false
  mirror.source = ""
  mirror.destination = ""
  mirror.error = ""
  publishMirror()
end

local function mirrorCheck()
  if mirror.stopping then
    return
  end
  noctalia.runAsync("pgrep -ax wl-mirror", function(res)
    if mirror.stopping then
      return
    end
    local source, destination
    for line in (res.stdout or ""):gmatch("[^\n]+") do
      local d, s = line:match("%-%-fullscreen%-output%s+(%S+)%s+(%S+)%s*$")
      if d ~= nil then
        destination = d
        source = s
        break
      end
    end
    if mirror.active and destination == nil then
      mirror.active = false
      mirror.source = ""
      mirror.destination = ""
      mirror.error = "wl-mirror exited unexpectedly"
      publishMirror()
    elseif not mirror.active and destination ~= nil then
      -- adopt a detached instance that survived a service restart; otherwise
      -- it is invisible, unkillable from the UI, and Start would stack a
      -- second wl-mirror on top of it
      mirror.active = true
      mirror.source = source
      mirror.destination = destination
      mirror.error = ""
      publishMirror()
    end
  end, 5000)
end

local function launchWdisplays()
  if not noctalia.commandExists("wdisplays") then
    noctalia.notifyError("Displays", "wdisplays is not installed")
    return
  end
  noctalia.runAsync("wdisplays")
end

local function dispatch(cmd)
  if type(cmd) ~= "table" or cmd.action == nil then
    return
  end
  local action = cmd.action
  if action == "refresh" then
    fetchOutputs()
    kanshiRefresh()
  elseif action == "apply" then
    applyOutput(cmd.output, cmd.opts or {}, cmd.revert ~= false)
  elseif action == "arrange" then
    applyArrangement(cmd.kind)
  elseif action == "keep" then
    confirmRevert()
  elseif action == "revertNow" then
    doRevert()
  elseif action == "kanshiSwitch" then
    switchProfile(cmd.name)
  elseif action == "kanshiSave" then
    saveProfile(cmd.name)
  elseif action == "kanshiDelete" then
    deleteProfile(cmd.name)
  elseif action == "kanshiReload" then
    kanshiReload()
  elseif action == "mirrorStart" then
    startMirror(cmd.source, cmd.destination)
  elseif action == "mirrorStop" then
    stopMirror()
  elseif action == "wdisplays" then
    launchWdisplays()
  else
    noctalia.log("displays: unknown command: " .. tostring(action))
  end
end

noctalia.state.watch("command", dispatch)

function update()
  if revert.pending then
    revert.secondsLeft -= 1
    if revert.secondsLeft <= 0 then
      doRevert()
    else
      publishRevert()
    end
    return
  end
  fetchOutputs()
  kanshiRefresh()
  mirrorCheck()
end

function onOutputsChanged()
  fetchOutputs()
  kanshiRefresh()
end

function onConfigChanged()
  loadConfig()
  if not revert.pending then
    noctalia.setUpdateInterval(pollMs)
  end
  fetchOutputs()
  kanshiRefresh()
end

function onIpc(event, payload)
  payload = type(payload) == "string" and noctalia.string.trim(payload) or ""
  if event == "toggle" then
    noctalia.togglePanel("fosskar/displays:panel")
  elseif event == "refresh" then
    fetchOutputs()
    kanshiRefresh()
  elseif event == "keep" then
    confirmRevert()
  elseif event == "revert" then
    doRevert()
  elseif event == "arrange" then
    applyArrangement(payload)
  elseif event == "kanshiSwitch" then
    switchProfile(payload)
  elseif event == "kanshiSave" then
    saveProfile(payload)
  elseif event == "mirrorStart" then
    local source, destination = payload:match("^(%S+)%s+(%S+)$")
    startMirror(source, destination)
  elseif event == "mirrorStop" then
    stopMirror()
  else
    noctalia.log("displays: unknown ipc event: " .. tostring(event))
  end
end

if not noctalia.commandExists("niri") then
  fetchState = "error"
  fetchError = "niri not found on PATH"
end

loadConfig()
noctalia.setUpdateInterval(pollMs)
publishOutputs()
publishRevert()
publishKanshi()
publishMirror()
if fetchState ~= "error" then
  fetchOutputs()
end
kanshiRefresh()
mirrorCheck()
