--!nonstrict
-- state channel (service -> ui):
--   outputs = { list, count, enabled, state = "loading"|"success"|"error", error }
--     list[i] = { name, make, model, serial, enabled, currentMode,
--                 modes = { { key, width, height, refresh, preferred } },
--                 scale, x, y, transform }
--   revert  = { pending, secondsLeft }
--   kanshi  = { enabled, available, active, profiles = { { name, managed } } }
--   mirror  = { available, active, source, destination, error }
--   gamemode = { available, active, output, mode, umbriel }
--   hotplug = number (nonce, bumped when output/enabled count changes)
-- state channel (ui -> service):
--   command = { action, ..., nonce }

local REVERT_SECONDS = 12

local pollMs = 30000
local kanshiEnabled = true
local kanshiDirOverride = ""
local gamemodeOutput = ""
local gamemodeMode = ""
local gamemodeUmbrielFile = ""

local function loadConfig()
  local secs = tonumber(noctalia.getConfig("poll_interval")) or 30
  pollMs = math.max(5, secs) * 1000
  kanshiEnabled = noctalia.getConfig("kanshi_enabled") ~= false
  local dir = noctalia.getConfig("kanshi_config_dir")
  kanshiDirOverride = type(dir) == "string" and dir or ""
  local output = noctalia.getConfig("gamemode_output")
  gamemodeOutput = type(output) == "string" and noctalia.string.trim(output) or ""
  local mode = noctalia.getConfig("gamemode_mode")
  gamemodeMode = type(mode) == "string" and noctalia.string.trim(mode) or ""
  local file = noctalia.getConfig("gamemode_umbriel_file")
  gamemodeUmbrielFile = type(file) == "string" and file or ""
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

local gamemode = { active = false }

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

local function underUmbriel()
  local socket = noctalia.getenv("UMBRIEL_SOCKET")
  return socket ~= nil and socket ~= "" and gamemodeUmbrielFile ~= ""
end

local function publishGamemode()
  noctalia.state.set("gamemode", {
    available = gamemodeOutput ~= "" and gamemodeMode ~= "",
    active = gamemode.active,
    output = gamemodeOutput,
    mode = gamemodeMode,
    umbriel = underUmbriel(),
  })
end

-- under umbriel a non-empty include file means game mode survived a service restart
local function syncGamemode()
  if underUmbriel() then
    local text = noctalia.readFile(noctalia.expandPath(gamemodeUmbrielFile))
    gamemode.active = type(text) == "string" and noctalia.string.trim(text) ~= ""
  end
  publishGamemode()
end

-- wlr-randr calls must run sequentially; re-query once the queue drains.
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
local function wlrOutputArgs(name, opts)
  local args = " --output " .. shellQuote(name)
  if opts.enabled == false then
    return args .. " --off"
  end
  if opts.enabled == true then
    args ..= " --on"
  end
  if opts.mode then
    args ..= " --mode " .. shellQuote(opts.mode)
  end
  if opts.scale then
    args ..= " --scale " .. tostring(opts.scale)
  end
  if opts.x ~= nil and opts.y ~= nil then
    args ..= " --pos " .. tostring(opts.x) .. "," .. tostring(opts.y)
  end
  if opts.transform then
    args ..= " --transform " .. shellQuote(opts.transform)
  end
  return args
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

-- one wlr-randr call applies all outputs as a single configuration
local function applySnapshot(snap)
  local cmd = "wlr-randr"
  for _, o in ipairs(snap) do
    local opts
    if o.enabled == false then
      opts = { enabled = false }
    else
      opts = { enabled = true, mode = o.mode, scale = o.scale, x = o.x, y = o.y, transform = o.transform }
    end
    cmd ..= wlrOutputArgs(o.name, opts)
  end
  enqueue({ cmd })
end

local function doRevert()
  local snap = revert.snapshot
  clearRevert()
  if snap ~= nil then
    applySnapshot(snap)
    noctalia.notify("Display reverted", "Change was not confirmed")
  end
end

-- opts as wlrOutputArgs; withRevert arms the countdown first
local function applyOutput(name, opts, withRevert)
  if withRevert then
    armRevert()
  end
  enqueue({ "wlr-randr" .. wlrOutputArgs(name, opts) })
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

-- wlr-output-management positions are logical px, hence logicalSize.
local function applyArrangement(kind)
  if #outputs ~= 2 then
    noctalia.notifyError("Displays", "Arrangements need exactly 2 outputs (have " .. #outputs .. ")")
    return
  end
  local laptop, external = splitLaptopExternal()
  local laptopSize, externalSize = logicalSize(laptop), logicalSize(external)
  local cmd = "wlr-randr"
  local function on(name)
    cmd ..= wlrOutputArgs(name, { enabled = true })
  end
  local function off(name)
    cmd ..= wlrOutputArgs(name, { enabled = false })
  end
  local function pos(name, x, y)
    cmd ..= wlrOutputArgs(name, { x = x, y = y })
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
  enqueue({ cmd })
end

-- formats like wlr-randr --mode expects; it matches refresh at mHz precision
local function formatHz(refreshHz)
  local hz = string.format("%.3f", refreshHz)
  hz = hz:gsub("0+$", ""):gsub("%.$", "")
  return hz
end

-- wlr-randr --json omits position, scale and transform for disabled heads
local function normalizeWlr(json)
  local list = {}
  for _, o in ipairs(json) do
    local modes = {}
    local currentMode = nil
    if type(o.modes) == "table" then
      for _, m in ipairs(o.modes) do
        local key = m.width .. "x" .. m.height .. "@" .. formatHz(m.refresh)
        table.insert(modes, {
          key = key,
          width = m.width,
          height = m.height,
          refresh = m.refresh,
          preferred = m.preferred == true,
        })
        if o.enabled and m.current then
          currentMode = key
        end
      end
    end

    table.sort(modes, function(x, y)
      local rx, ry = x.width * x.height, y.width * y.height
      if rx ~= ry then
        return rx > ry
      end
      return x.refresh > y.refresh
    end)

    table.insert(list, {
      name = o.name,
      make = o.make or "",
      model = o.model or "",
      serial = o.serial or "",
      enabled = o.enabled == true,
      currentMode = currentMode,
      modes = modes,
      scale = o.scale or 1.0,
      x = o.position ~= nil and o.position.x or 0,
      y = o.position ~= nil and o.position.y or 0,
      transform = o.transform or "normal",
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
  noctalia.runAsync("wlr-randr --json", function(res)
    fetching = false
    if res.exitCode ~= 0 then
      fetchState = "error"
      fetchError = noctalia.string.trim(res.stderr ~= "" and res.stderr or ("wlr-randr exited " .. res.exitCode))
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

    outputs = normalizeWlr(json)
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
      -- the revert snapshot describes the old monitor set; replaying it would
      -- address missing outputs and undo the layout kanshi just applied
      if lastOutputCount ~= outputCount and revert.pending then
        clearRevert()
      end
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
  -- kanshictl status prints "Current profile: <name>", or "(none)"
  noctalia.runAsync("kanshictl status", function(res)
    kanshi.available = res.exitCode == 0
    local active = kanshi.available and (res.stdout or ""):match("Current profile: ([^\n]+)") or nil
    kanshi.active = (active ~= nil and active ~= "(none)") and active or ""
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

local function setGamemode(on)
  if gamemodeOutput == "" or gamemodeMode == "" then
    noctalia.notifyError("Displays", "Game mode needs gamemode_output and gamemode_mode")
    return
  end
  if on == gamemode.active then
    return
  end
  local umbriel = underUmbriel()
  local path = noctalia.expandPath(gamemodeUmbrielFile)
  if on then
    local cmd = "wlr-randr --output " .. shellQuote(gamemodeOutput) .. " --custom-mode " .. shellQuote(gamemodeMode)
    if umbriel then
      local ok, err = noctalia.writeFile(path, '[output."' .. gamemodeOutput .. '"]\nhdr = "off"\n')
      if not ok then
        noctalia.notifyError("Displays", "Failed to write " .. path .. ": " .. tostring(err))
        return
      end
      -- the include reload resets the output to its configured mode, so the
      -- custom mode has to land after umbriel reports HDR off
      local ready = shellQuote("^output " .. gamemodeOutput .. ": HDR mode off,")
      cmd = "for i in $(seq 50); do umbriel color | grep -q " .. ready .. " && break; sleep 0.1; done; " .. cmd
    end
    enqueue({ cmd })
  elseif umbriel then
    -- the reload reapplies the configured mode and HDR
    local ok, err = noctalia.writeFile(path, "")
    if not ok then
      noctalia.notifyError("Displays", "Failed to write " .. path .. ": " .. tostring(err))
      return
    end
  elseif kanshi.available then
    kanshiReload()
  else
    noctalia.notifyError("Displays", "No kanshi to restore " .. gamemodeOutput .. "; set its mode manually")
  end
  gamemode.active = on
  publishGamemode()
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
  elseif action == "gamemode" then
    setGamemode(cmd.on == true)
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
  -- outputs are event-driven (onOutputsChanged + panel-open refresh); the
  -- periodic tick only reconciles kanshi/wl-mirror, which have no events.
  kanshiRefresh()
  mirrorCheck()
end

function onOutputsChanged()
  fetchOutputs()
  kanshiRefresh()
end

function onConfigChanged()
  loadConfig()
  syncGamemode()
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
  elseif event == "gamemode" then
    if payload == "on" then
      setGamemode(true)
    elseif payload == "off" then
      setGamemode(false)
    else
      setGamemode(not gamemode.active)
    end
  else
    noctalia.log("displays: unknown ipc event: " .. tostring(event))
  end
end

if not noctalia.commandExists("wlr-randr") then
  fetchState = "error"
  fetchError = "wlr-randr not found on PATH"
end

loadConfig()
noctalia.setUpdateInterval(pollMs)
publishOutputs()
publishRevert()
publishKanshi()
publishMirror()
syncGamemode()
if fetchState ~= "error" then
  fetchOutputs()
end
kanshiRefresh()
mirrorCheck()
