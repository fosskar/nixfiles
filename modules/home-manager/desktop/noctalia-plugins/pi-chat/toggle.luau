local command = barWidget.getConfig("command")

local function render()
  barWidget.setGlyph("message-chatbot")
  barWidget.setText("pi")
  barWidget.setTooltip("Toggle pi-chat")
end

render()

function update()
  noctalia.setUpdateInterval(60000)
  render()
end

function onClick()
  noctalia.runAsync(command)
end

function onRightClick()
  noctalia.runAsync(command)
end

function onIpc(event, _payload)
  if event == "toggle" then
    noctalia.runAsync(command)
  end
end
