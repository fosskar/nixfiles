--!nonstrict

local outputsState = { count = 0, enabled = 0, state = "loading", error = "" }
local revertState = { pending = false, secondsLeft = 0 }
local kanshiState = { active = "" }
local mirrorState = { active = false, source = "", destination = "" }

local pulseTicksLeft = 0
local cmdNonce = math.random(1, 1000000)

local function sendCommand(cmd)
  cmdNonce += 1
  cmd.nonce = cmdNonce
  noctalia.state.set("command", cmd)
end

local function render()
  if mirrorState.active then
    barWidget.setGlyph("screen-share")
  else
    barWidget.setGlyph("device-desktop")
  end

  if revertState.pending then
    barWidget.setText(revertState.secondsLeft .. "s")
    barWidget.setGlyphColor("tertiary")
  else
    barWidget.setText("")
    if pulseTicksLeft > 0 then
      barWidget.setGlyphColor("primary")
    elseif outputsState.state == "error" then
      barWidget.setGlyphColor("error")
    else
      barWidget.setGlyphColor("on_surface")
    end
  end

  local rows = {}
  if outputsState.state == "error" then
    table.insert(rows, { key = "Outputs", value = outputsState.error })
  else
    table.insert(rows, { key = "Outputs", value = outputsState.enabled .. "/" .. outputsState.count .. " enabled" })
  end
  if kanshiState.active ~= nil and kanshiState.active ~= "" then
    table.insert(rows, { key = "Profile", value = kanshiState.active })
  end
  if mirrorState.active then
    table.insert(rows, { key = "Mirror", value = mirrorState.source .. " → " .. mirrorState.destination })
  end
  if revertState.pending then
    table.insert(rows, { key = "Pending", value = "reverting in " .. revertState.secondsLeft .. "s" })
  end
  barWidget.setTooltip(rows)
end

function update()
  if pulseTicksLeft > 0 then
    pulseTicksLeft -= 1
    if pulseTicksLeft == 0 then
      noctalia.setUpdateInterval(3600000)
    end
    render()
  end
end

function onClick()
  noctalia.togglePanel("fosskar/displays:panel")
end

function onRightClick()
  sendCommand({ action = "refresh" })
end

function onMiddleClick()
  if mirrorState.active then
    sendCommand({ action = "mirrorStop" })
  end
end

noctalia.state.watch("outputs", function(value)
  if type(value) == "table" then
    outputsState = value
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
    render()
  end
end)

noctalia.state.watch("mirror", function(value)
  if type(value) == "table" then
    mirrorState = value
    render()
  end
end)

noctalia.state.watch("hotplug", function(_)
  pulseTicksLeft = 6
  noctalia.setUpdateInterval(500)
  render()
end)

noctalia.setUpdateInterval(3600000)
render()
