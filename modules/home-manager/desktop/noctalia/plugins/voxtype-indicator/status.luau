local command = noctalia.getConfig("command") or "voxtype"
local hideIdle = noctalia.getConfig("hide_idle") == true
local state = { class = "stopped", tooltip = "Voxtype not running", since = 0 }

local function isRecording()
  return state.class == "recording" or state.class == "streaming"
end

local function elapsed()
  local secs = math.max(0, os.time() - (state.since or 0))
  return string.format("%d:%02d", secs // 60, secs % 60)
end

local function render()
  local class = state.class or "stopped"

  if isRecording() then
    barWidget.setGlyph("microphone")
    barWidget.setGlyphColor("error")
    barWidget.setColor("error")
    barWidget.setText(elapsed())
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
  elseif class == "error" then
    barWidget.setGlyph("microphone-off")
    barWidget.setGlyphColor("error")
    barWidget.setText("")
    barWidget.setVisible(true)
  else
    barWidget.setGlyph("microphone-off")
    barWidget.setGlyphColor("on_surface_variant")
    barWidget.setText("")
    barWidget.setVisible(not hideIdle)
  end

  barWidget.setTooltip(state.tooltip or "Voxtype")
end

function update()
  if isRecording() then
    render()
  end
end

function onClick()
  noctalia.runAsync({ command, "record", "toggle" })
end

function onRightClick()
  noctalia.runAsync({ command, "record", "cancel" })
end

local function applyStatus(value)
  if type(value) == "table" then
    state = value
  end
  -- tick once a second only while the timer is visible
  noctalia.setUpdateInterval(isRecording() and 1000 or 3600000)
  render()
end

applyStatus(noctalia.state.get("status"))
noctalia.state.watch("status", applyStatus)
