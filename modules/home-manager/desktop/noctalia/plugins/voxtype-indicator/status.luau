local command = noctalia.getConfig("command") or "voxtype"
local hideIdle = noctalia.getConfig("hide_idle") == true
local state = { class = "stopped", tooltip = "Voxtype not running" }

local function render()
  local class = state.class or "stopped"

  if class == "recording" or class == "streaming" then
    barWidget.setGlyph("microphone")
    barWidget.setGlyphColor("error")
    barWidget.setColor("error")
    barWidget.setText("rec")
    barWidget.setVisible(true)
  elseif class == "transcribing" then
    barWidget.setGlyph("loader")
    barWidget.setGlyphColor("primary")
    barWidget.setColor("primary")
    barWidget.setText("asr")
    barWidget.setVisible(true)
  elseif class == "idle" then
    barWidget.setGlyph("message-square-text")
    barWidget.setGlyphColor("on_surface")
    barWidget.setText("")
    barWidget.setVisible(not hideIdle)
  else
    barWidget.setGlyph("microphone-off")
    barWidget.setGlyphColor("on_surface_variant")
    barWidget.setText("")
    barWidget.setVisible(not hideIdle)
  end

  -- the --extended tooltip already lists model, device and backend
  barWidget.setTooltip(state.tooltip or "Voxtype")
end

function onClick()
  noctalia.runAsync(command .. " record toggle")
end

function onRightClick()
  noctalia.runAsync(command .. " record cancel")
end

local function applyStatus(value)
  if type(value) == "table" then
    state = value
  end
  render()
end

applyStatus(noctalia.state.get("status"))
noctalia.state.watch("status", applyStatus)
