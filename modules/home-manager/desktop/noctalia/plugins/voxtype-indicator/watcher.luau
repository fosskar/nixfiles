local command = noctalia.getConfig("command") or "voxtype"

local function shellQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local lastClass = nil
local since = 0

local function publish(class, tooltip)
  -- since marks the last class change; the widget derives the recording timer from it
  if class ~= lastClass then
    lastClass = class
    since = os.time()
  end
  noctalia.state.set("status", { class = class, tooltip = tooltip, since = since })
end

local function publishLine(line)
  local status = noctalia.json.decode(line)
  if type(status) ~= "table" then
    publish("error", "Unreadable voxtype status: " .. line)
    return
  end
  publish(status.class or "stopped", status.tooltip or "Voxtype")
end

local function start()
  if not noctalia.commandExists(command) then
    publish("error", "'" .. command .. "' not found on PATH")
    return
  end

  -- `status --follow` exits immediately on a config error (for example a
  -- disabled state_file) and the stream reports no exit, so probe once first
  noctalia.runAsync({ command, "status", "--format", "json", "--extended" }, function(res)
    if res.exitCode ~= 0 then
      local err = noctalia.string.trim(res.stderr ~= "" and res.stderr or res.stdout)
      publish("error", "voxtype status failed: " .. (err:match("[^\n]+") or ("exit " .. res.exitCode)))
      return
    end
    publishLine(noctalia.string.trim(res.stdout))
    local cmd = shellQuote(command) .. " status --follow --format json --extended"
    if not noctalia.runStream(cmd, publishLine) then
      publish("error", "Failed to start '" .. cmd .. "'")
    end
  end, 10000)
end

start()
