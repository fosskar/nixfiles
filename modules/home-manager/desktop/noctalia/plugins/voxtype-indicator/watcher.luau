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
    model = status.model or "",
    backend = status.backend or "",
  })
end

local function start()
  if not noctalia.commandExists(command) then
    publish({ class = "stopped", tooltip = command .. " not found" })
    return
  end

  noctalia.runStream(command .. " status --follow --format json --extended", function(line)
    local class = line:match('"class"%s*:%s*"([^"]+)"') or "stopped"
    local alt = line:match('"alt"%s*:%s*"([^"]+)"') or class
    local text = line:match('"text"%s*:%s*"([^"]*)"') or ""
    local tooltip = line:match('"tooltip"%s*:%s*"([^"]*)"') or "Voxtype"
    local model = line:match('"model"%s*:%s*"([^"]*)"') or ""
    local backend = line:match('"backend"%s*:%s*"([^"]*)"') or ""

    publish({
      class = class,
      alt = alt,
      text = text,
      tooltip = tooltip,
      model = model,
      backend = backend,
    })
  end)
end

start()
