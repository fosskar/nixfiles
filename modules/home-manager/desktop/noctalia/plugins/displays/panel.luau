--!nonstrict
-- All mutations go to the service via the "command" state channel; this file
-- only renders published state.

local MAX_SLOTS = 6 -- per-output callback slots declared at the bottom
local SCALES = { 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0 }

local outputsState = { list = {}, count = 0, enabled = 0, state = "loading", error = "" }
local revertState = { pending = false, secondsLeft = 0 }
local kanshiState = { enabled = false, available = false, active = "", profiles = {} }
local mirrorState = { available = false, active = false, source = "", destination = "", error = "" }

local selectedProfile = "" -- follows kanshi.active until the user picks one
local userPickedProfile = false
local typedProfileName = ""
local profileInputNonce = 0 -- bumped to reset the uncontrolled input after a save

local mirrorSource = ""
local mirrorDestination = ""

local cmdNonce = math.random(1, 1000000)

-- slot -> per-output callback payloads for the current render
local powerSlots = {}
local modeSlots = {} -- { output = name, keys = { modeKey } }
local scaleSlots = {} -- { output = name, values = { number } }

local render

local function sendCommand(cmd)
  cmdNonce += 1
  cmd.nonce = cmdNonce
  noctalia.state.set("command", cmd)
end

local function formatScale(scale)
  return tostring(math.floor(scale * 100 + 0.5)) .. "%"
end

local function formatRefresh(hz)
  local s = string.format("%.2f", hz)
  s = s:gsub("0+$", ""):gsub("%.$", "")
  return s .. "Hz"
end

-- Group near-duplicate refresh variants: the first (highest-refresh) mode per
-- resolution shows "2560×1440  165Hz", later ones an indented "    144Hz".
local function modeOptions(o)
  local options = {}
  local keys = {}
  local seenRes = {}
  local selectedIndex = 0
  for i, m in ipairs(o.modes) do
    local res = m.width .. "×" .. m.height
    local label
    if not seenRes[res] then
      seenRes[res] = true
      label = res .. "  " .. formatRefresh(m.refresh) .. (m.preferred and " ★" or "")
    else
      label = "      " .. formatRefresh(m.refresh) .. (m.preferred and " ★" or "")
    end
    table.insert(options, label)
    table.insert(keys, m.key)
    if m.key == o.currentMode then
      selectedIndex = i - 1
    end
  end
  return options, keys, selectedIndex
end

local function scaleOptions(o)
  local options = {}
  local values = {}
  local selectedIndex = 0
  local matched = false
  for _, s in ipairs(SCALES) do
    if not matched and math.abs(s - o.scale) < 0.001 then
      matched = true
      selectedIndex = #options
    end
    table.insert(options, formatScale(s))
    table.insert(values, s)
  end
  if not matched then
    -- current scale is off-grid (e.g. set by kanshi); show it as first entry
    table.insert(options, 1, formatScale(o.scale))
    table.insert(values, 1, o.scale)
    selectedIndex = 0
  end
  return options, values, selectedIndex
end

local function enabledOutputs()
  local list = {}
  for _, o in ipairs(outputsState.list) do
    if o.enabled then
      table.insert(list, o)
    end
  end
  return list
end

local function header()
  local text
  if outputsState.state == "error" then
    text = "Output query failed"
  else
    text = outputsState.enabled .. "/" .. outputsState.count .. " outputs enabled"
  end
  return ui.row({ align = "center", gap = 8 }, {
    ui.glyph({ name = "device-desktop", size = 20, color = "primary" }),
    ui.label({ text = text, fontSize = 15, fontWeight = "bold", flexGrow = 1 }),
    ui.button({ glyph = "refresh", variant = "ghost", onClick = "onRefresh" }),
    ui.button({ glyph = "external-link", variant = "ghost", onClick = "onWdisplays" }),
    ui.button({ glyph = "x", variant = "ghost", onClick = "onClosePanel" }),
  })
end

local function revertBar()
  return ui.row({ align = "center", gap = 8, fill = "tertiary", radius = 10, padding = 10 }, {
    ui.glyph({ name = "alert-triangle", size = 16, color = "on_tertiary" }),
    ui.label({
      text = "Reverting in " .. revertState.secondsLeft .. "s",
      fontWeight = "bold",
      color = "on_tertiary",
      flexGrow = 1,
    }),
    ui.button({ text = "Revert", glyph = "restore", variant = "outline", onClick = "onRevertNow" }),
    ui.button({ text = "Keep", glyph = "check", variant = "primary", onClick = "onKeep" }),
  })
end

local function outputCard(o, slot)
  powerSlots[slot] = o.name
  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({
        name = o.enabled and "device-desktop" or "device-desktop-off",
        size = 18,
        color = o.enabled and "primary" or "on_surface_variant",
      }),
      ui.column({ gap = 0, flexGrow = 1 }, {
        ui.label({ text = o.name, fontWeight = "bold" }),
        ui.label({
          text = noctalia.string.trim(o.make .. " " .. o.model),
          fontSize = 11,
          color = "on_surface_variant",
          visible = o.make ~= "" or o.model ~= "",
        }),
      }),
      ui.toggle({ checked = o.enabled, onChange = "onPower" .. slot }),
    }),
  }

  if o.enabled and #o.modes > 0 then
    local options, keys, selectedIndex = modeOptions(o)
    modeSlots[slot] = { output = o.name, keys = keys, current = o.currentMode }
    table.insert(
      children,
      ui.row({ align = "center", gap = 8 }, {
        ui.label({ text = "Mode", fontSize = 12, color = "on_surface_variant", width = 50 }),
        ui.select({
          key = o.name .. "-mode",
          options = options,
          selectedIndex = selectedIndex,
          onChange = "onMode" .. slot,
          flexGrow = 1,
        }),
      })
    )

    local scaleOpts, scaleValues, scaleIndex = scaleOptions(o)
    scaleSlots[slot] = { output = o.name, values = scaleValues, current = o.scale }
    table.insert(
      children,
      ui.row({ align = "center", gap = 8 }, {
        ui.label({ text = "Scale", fontSize = 12, color = "on_surface_variant", width = 50 }),
        ui.select({
          key = o.name .. "-scale",
          options = scaleOpts,
          selectedIndex = scaleIndex,
          onChange = "onScale" .. slot,
          flexGrow = 1,
        }),
      })
    )
  end

  return ui.column({ gap = 8, padding = 12, fill = "surface_variant", radius = 12, key = o.name }, children)
end

local function arrangeSection()
  local function btn(text, glyph, onClick)
    return ui.button({ text = text, glyph = glyph, onClick = onClick, flexGrow = 1 })
  end
  return ui.column({ gap = 6 }, {
    ui.separator({}),
    ui.label({ text = "Arrange", fontWeight = "bold" }),
    ui.row({ gap = 6 }, {
      btn("Extend right", "arrow-bar-right", "onArrangeExtendRight"),
      btn("Extend left", "arrow-bar-left", "onArrangeExtendLeft"),
    }),
    ui.row({ gap = 6 }, {
      btn("External above", "arrow-bar-to-up", "onArrangeAbove"),
      btn("External below", "arrow-bar-to-down", "onArrangeBelow"),
    }),
    ui.row({ gap = 6 }, {
      btn("External only", "device-desktop", "onArrangeExternalOnly"),
      btn("Laptop only", "device-laptop", "onArrangeInternalOnly"),
    }),
  })
end

local function manyMonitorsSection()
  return ui.column({ gap = 6 }, {
    ui.separator({}),
    ui.label({
      text = "With " .. outputsState.count .. " monitors, arrange them in wdisplays and save the result as a kanshi profile.",
      fontSize = 12,
      color = "on_surface_variant",
    }),
    ui.button({ text = "Open wdisplays", glyph = "external-link", onClick = "onWdisplays" }),
  })
end

local function selectedProfileEntry()
  for _, p in ipairs(kanshiState.profiles) do
    if p.name == selectedProfile then
      return p
    end
  end
  return nil
end

local function kanshiSection()
  local children = {
    ui.separator({}),
    ui.row({ align = "center", gap = 8 }, {
      ui.label({ text = "Kanshi profiles", fontWeight = "bold", flexGrow = 1 }),
      ui.label({
        text = "kanshictl unavailable",
        fontSize = 11,
        color = "error",
        visible = not kanshiState.available,
      }),
      ui.button({ glyph = "refresh", variant = "ghost", onClick = "onKanshiReload" }),
    }),
  }

  if #kanshiState.profiles == 0 then
    table.insert(children, ui.label({ text = "No profiles yet — save the current layout below.", fontSize = 12, color = "on_surface_variant" }))
  else
    local options = {}
    local selectedIndex = 0
    local matched = false
    for i, p in ipairs(kanshiState.profiles) do
      local label = p.name
      if p.name == kanshiState.active then
        label = "✓ " .. label
      end
      if not p.managed then
        label = label .. "  [nix]"
      end
      table.insert(options, label)
      if p.name == selectedProfile then
        selectedIndex = i - 1
        matched = true
      end
    end
    if not matched then
      selectedProfile = kanshiState.profiles[1].name
    end
    local entry = selectedProfileEntry()
    local managed = entry ~= nil and entry.managed
    table.insert(
      children,
      ui.row({ align = "center", gap = 6 }, {
        ui.select({
          key = "kanshi-profile",
          options = options,
          selectedIndex = selectedIndex,
          onChange = "onProfileSelect",
          flexGrow = 1,
        }),
        ui.button({ glyph = "refresh-dot", variant = "ghost", enabled = managed, onClick = "onProfileUpdate" }),
        ui.button({ glyph = "trash", variant = "ghost", enabled = managed, onClick = "onProfileDelete" }),
      })
    )
  end

  table.insert(
    children,
    ui.row({ align = "center", gap = 6 }, {
      ui.input({
        key = "profile-name-" .. profileInputNonce,
        placeholder = "New profile name…",
        fontSize = 13,
        onChange = "onProfileName",
        onSubmit = "onProfileSave",
        flexGrow = 1,
      }),
      ui.button({
        text = "Save",
        glyph = "device-floppy",
        enabled = noctalia.string.trim(typedProfileName) ~= "",
        onClick = "onProfileSave",
      }),
    })
  )

  return ui.column({ gap = 8 }, children)
end

local function mirrorSection()
  local active = enabledOutputs()
  local names = {}
  for _, o in ipairs(active) do
    table.insert(names, o.name)
  end

  local children = {
    ui.separator({}),
    ui.label({ text = "Mirror", fontWeight = "bold" }),
  }

  if not mirrorState.available then
    table.insert(children, ui.label({ text = "wl-mirror is not installed", fontSize = 12, color = "error" }))
  elseif mirrorState.active then
    table.insert(
      children,
      ui.row({ align = "center", gap = 8 }, {
        ui.glyph({ name = "screen-share", size = 16, color = "primary" }),
        ui.label({
          text = "Mirroring " .. mirrorState.source .. " → " .. mirrorState.destination,
          flexGrow = 1,
        }),
        ui.button({ text = "Stop", glyph = "player-stop", variant = "destructive", onClick = "onMirrorStop" }),
      })
    )
  elseif #names < 2 then
    table.insert(children, ui.label({ text = "Mirroring needs at least 2 enabled outputs.", fontSize = 12, color = "on_surface_variant" }))
  else
    local sourceIndex, destIndex = 0, 0
    for i, n in ipairs(names) do
      if n == mirrorSource then
        sourceIndex = i - 1
      end
      if n == mirrorDestination then
        destIndex = i - 1
      end
    end
    table.insert(
      children,
      ui.row({ align = "center", gap = 6 }, {
        ui.select({
          key = "mirror-source",
          options = names,
          selectedIndex = sourceIndex,
          onChange = "onMirrorSource",
          flexGrow = 1,
        }),
        ui.glyph({ name = "arrow-right", size = 14, color = "on_surface_variant" }),
        ui.select({
          key = "mirror-dest",
          options = names,
          selectedIndex = destIndex,
          onChange = "onMirrorDest",
          flexGrow = 1,
        }),
        ui.button({
          text = "Start",
          glyph = "player-play",
          variant = "primary",
          enabled = mirrorSource ~= mirrorDestination,
          onClick = "onMirrorStart",
        }),
      })
    )
    if mirrorSource == mirrorDestination then
      table.insert(children, ui.label({ text = "Source and destination must differ.", fontSize = 12, color = "error" }))
    end
  end

  if mirrorState.error ~= "" then
    table.insert(children, ui.label({ text = mirrorState.error, fontSize = 12, color = "error" }))
  end

  return ui.column({ gap = 8 }, children)
end

render = function()
  powerSlots = {}
  modeSlots = {}
  scaleSlots = {}

  local body = {}

  if outputsState.state == "error" then
    table.insert(body, ui.label({ text = outputsState.error, color = "error", fontSize = 12 }))
  end

  for i, o in ipairs(outputsState.list) do
    if i > MAX_SLOTS then
      break
    end
    table.insert(body, outputCard(o, i - 1))
  end

  if outputsState.count == 2 then
    table.insert(body, arrangeSection())
  elseif outputsState.count > 2 then
    table.insert(body, manyMonitorsSection())
  end

  if kanshiState.enabled then
    table.insert(body, kanshiSection())
  end

  table.insert(body, mirrorSection())

  local root = { header() }
  if revertState.pending then
    table.insert(root, revertBar())
  end
  table.insert(root, ui.scroll({ flexGrow = 1, gap = 10 }, body))

  panel.render(ui.column({ flexGrow = 1, gap = 10 }, root))
end

local function syncMirrorSelection()
  local active = enabledOutputs()
  local function present(name)
    for _, o in ipairs(active) do
      if o.name == name then
        return true
      end
    end
    return false
  end
  if #active == 0 then
    mirrorSource = ""
    mirrorDestination = ""
    return
  end
  if mirrorSource == "" or not present(mirrorSource) then
    mirrorSource = noctalia.focusedOutputName() or active[1].name
    if not present(mirrorSource) then
      mirrorSource = active[1].name
    end
  end
  if mirrorDestination == "" or not present(mirrorDestination) or mirrorDestination == mirrorSource then
    mirrorDestination = mirrorSource
    for _, o in ipairs(active) do
      if o.name ~= mirrorSource then
        mirrorDestination = o.name
        break
      end
    end
  end
end

function onOpen(_context)
  outputsState = noctalia.state.get("outputs") or outputsState
  revertState = noctalia.state.get("revert") or revertState
  kanshiState = noctalia.state.get("kanshi") or kanshiState
  mirrorState = noctalia.state.get("mirror") or mirrorState
  if not userPickedProfile then
    selectedProfile = kanshiState.active or ""
  end
  syncMirrorSelection()
  sendCommand({ action = "refresh" })
  render()
end

function onClosePanel()
  panel.close()
end

function onRefresh()
  sendCommand({ action = "refresh" })
end

function onWdisplays()
  sendCommand({ action = "wdisplays" })
  panel.close()
end

function onKeep()
  sendCommand({ action = "keep" })
end

function onRevertNow()
  sendCommand({ action = "revertNow" })
end

function onProfileSelect(index, _label)
  local i = tonumber(index)
  if i == nil then
    return
  end
  local p = kanshiState.profiles[i + 1]
  if p == nil then
    return
  end
  selectedProfile = p.name
  userPickedProfile = true
  sendCommand({ action = "kanshiSwitch", name = p.name })
  render()
end

function onProfileUpdate()
  local p = selectedProfileEntry()
  if p ~= nil and p.managed then
    sendCommand({ action = "kanshiSave", name = p.name })
  end
end

function onProfileDelete()
  local p = selectedProfileEntry()
  if p ~= nil and p.managed then
    sendCommand({ action = "kanshiDelete", name = p.name })
    selectedProfile = ""
    userPickedProfile = false
  end
end

function onKanshiReload()
  sendCommand({ action = "kanshiReload" })
end

function onProfileName(text)
  typedProfileName = tostring(text or "")
  render() -- keeps the Save button's enabled state in sync
end

function onProfileSave()
  local name = noctalia.string.trim(typedProfileName)
  if name == "" then
    return
  end
  sendCommand({ action = "kanshiSave", name = name })
  selectedProfile = name
  userPickedProfile = true
  typedProfileName = ""
  profileInputNonce += 1 -- fresh key resets the uncontrolled input
  render()
end

function onMirrorSource(_index, label)
  if type(label) == "string" and label ~= "" then
    mirrorSource = label
    render()
  end
end

function onMirrorDest(_index, label)
  if type(label) == "string" and label ~= "" then
    mirrorDestination = label
    render()
  end
end

function onMirrorStart()
  sendCommand({ action = "mirrorStart", source = mirrorSource, destination = mirrorDestination })
end

function onMirrorStop()
  sendCommand({ action = "mirrorStop" })
end

function onArrangeExtendRight()
  sendCommand({ action = "arrange", kind = "extend-right" })
end

function onArrangeExtendLeft()
  sendCommand({ action = "arrange", kind = "extend-left" })
end

function onArrangeAbove()
  sendCommand({ action = "arrange", kind = "stack-above" })
end

function onArrangeBelow()
  sendCommand({ action = "arrange", kind = "stack-below" })
end

function onArrangeExternalOnly()
  sendCommand({ action = "arrange", kind = "external-only" })
end

function onArrangeInternalOnly()
  sendCommand({ action = "arrange", kind = "internal-only" })
end

local function powerAt(slot, value)
  local name = powerSlots[slot]
  if name ~= nil then
    sendCommand({ action = "apply", output = name, opts = { enabled = value == "true" }, revert = true })
  end
end

local function modeAt(slot, index)
  local s = modeSlots[slot]
  local i = tonumber(index)
  if s == nil or i == nil then
    return
  end
  local key = s.keys[i + 1]
  if key ~= nil and key ~= s.current then
    sendCommand({ action = "apply", output = s.output, opts = { mode = key }, revert = true })
  end
end

local function scaleAt(slot, index)
  local s = scaleSlots[slot]
  local i = tonumber(index)
  if s == nil or i == nil then
    return
  end
  local value = s.values[i + 1]
  if value ~= nil and math.abs(value - s.current) > 0.001 then
    sendCommand({ action = "apply", output = s.output, opts = { scale = value }, revert = true })
  end
end

function onPower0(v) powerAt(0, v) end
function onPower1(v) powerAt(1, v) end
function onPower2(v) powerAt(2, v) end
function onPower3(v) powerAt(3, v) end
function onPower4(v) powerAt(4, v) end
function onPower5(v) powerAt(5, v) end

function onMode0(i) modeAt(0, i) end
function onMode1(i) modeAt(1, i) end
function onMode2(i) modeAt(2, i) end
function onMode3(i) modeAt(3, i) end
function onMode4(i) modeAt(4, i) end
function onMode5(i) modeAt(5, i) end

function onScale0(i) scaleAt(0, i) end
function onScale1(i) scaleAt(1, i) end
function onScale2(i) scaleAt(2, i) end
function onScale3(i) scaleAt(3, i) end
function onScale4(i) scaleAt(4, i) end
function onScale5(i) scaleAt(5, i) end

noctalia.state.watch("outputs", function(value)
  if type(value) == "table" then
    outputsState = value
    syncMirrorSelection()
    render()
  end
end)

noctalia.state.watch("revert", function(value)
  if type(value) == "table" then
    revertState = value
    render()
  end
end)

noctalia.state.watch("kanshi", function(value)
  if type(value) == "table" then
    kanshiState = value
    if not userPickedProfile then
      selectedProfile = kanshiState.active or ""
    end
    render()
  end
end)

noctalia.state.watch("mirror", function(value)
  if type(value) == "table" then
    mirrorState = value
    render()
  end
end)
