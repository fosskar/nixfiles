local command = noctalia.getConfig("command") or "voxtype"

local function publish(status)
  if type(status) ~= "table" then
    status = {}
  end

  noctalia.state.set("status", {
    class = status.class or "stopped",
    alt = status.alt or status.class or "stopped",
    text = status.text or "",
    tooltip = status.tooltip or "Voxtype status unavailable",
  })
end

local function start()
  if not noctalia.commandExists(command) then
    publish({ class = "stopped", tooltip = command .. " not found" })
    return
  end

  noctalia.runStream(command .. " status --follow --format json --extended", function(line)
    publish(noctalia.json.decode(line))
  end)
end

start()
