local command = noctalia.getConfig("command")

local function render()
  shortcut.setLabel("pi-chat")
  shortcut.setIcon("message-chatbot")
  shortcut.setActive(false)
  shortcut.setEnabled(true)
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
