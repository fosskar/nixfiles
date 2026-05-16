local niri = "@niri@"
local jq = "@jq@"
local wl_mirror = "@wl_mirror@"
local wdisplays = "@wdisplays@"
local kanshictl = "@kanshictl@"
local pkill = "@pkill@"
local pgrep = "@pgrep@"
local sh = "@sh@"

local function cfg(key, default)
  local value = barWidget.getConfig(key, default)
  if value == nil or value == "" then
    return default
  end
  return value
end

local function q(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function jq_key(s)
  return "[\"" .. tostring(s):gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"]"
end

local function run(command)
  local code, out, err = noctalia.runSync(command)
  return code, out or "", err or ""
end

local function run_async(command)
  return noctalia.runAsync(command)
end

local function lines(text)
  local result = {}
  for line in text:gmatch("[^\r\n]+") do
    if line ~= "" then
      table.insert(result, line)
    end
  end
  return result
end

local function outputs_query(filter)
  local code, out = run(niri .. " msg -j outputs | " .. jq .. " -r " .. q(filter))
  if code ~= 0 then
    return {}
  end
  return lines(out)
end

local function enabled_outputs()
  return outputs_query("to_entries | map(select(.value.current_mode != null)) | sort_by(.key) | .[].key")
end

local function all_outputs()
  return outputs_query("to_entries | sort_by(.key) | .[].key")
end

local function is_internal(name)
  local lower = string.lower(name or "")
  return lower:match("^edp") ~= nil or lower:match("^lvds") ~= nil or lower:match("^dsi") ~= nil
end

local function mirror_running()
  local code = run(pgrep .. " -x wl-mirror >/dev/null")
  return code == 0
end

local function stop_mirror()
  run(pkill .. " -TERM -x wl-mirror >/dev/null 2>&1 || true")
  update()
end

local function mirror_pair()
  local source = cfg("source", "")
  local destination = cfg("destination", "")
  if source ~= "" and destination ~= "" and source ~= destination then
    return source, destination
  end

  local outputs = enabled_outputs()
  if #outputs < 2 then
    outputs = all_outputs()
  end
  if #outputs < 2 then
    return nil, nil
  end

  local internal = nil
  local external = nil
  for _, output in ipairs(outputs) do
    if is_internal(output) then
      internal = output
    elseif external == nil then
      external = output
    end
  end

  source = cfg("source", external or outputs[1])
  destination = cfg("destination", internal or outputs[2])
  if source == destination then
    destination = outputs[2]
  end
  return source, destination
end

local function start_mirror()
  if mirror_running() then
    stop_mirror()
    return
  end

  local source, destination = mirror_pair()
  if source == nil or destination == nil or source == destination then
    noctalia.notifyError("mirror-mirror", "need two distinct outputs")
    return
  end

  run_async(wl_mirror .. " --fullscreen-output " .. q(destination) .. " " .. q(source))
  noctalia.notify("mirror-mirror", "mirroring " .. source .. " to " .. destination)
  update()
end

local function output_size(name)
  local key = jq_key(name)
  local filter = "[." .. key .. ".modes[." .. key .. ".current_mode].width, ." .. key .. ".modes[." .. key .. ".current_mode].height, (." .. key .. ".logical.scale // 1)] | @tsv"
  local code, out = run(niri .. " msg -j outputs | " .. jq .. " -r " .. q(filter))
  if code ~= 0 then
    return 1920, 1080
  end

  local w, h, scale = out:match("(%d+)%s+(%d+)%s+([%d%.]+)")
  w = tonumber(w) or 1920
  h = tonumber(h) or 1080
  scale = tonumber(scale) or 1
  return math.floor((w / scale) + (1 / 2)), math.floor((h / scale) + (1 / 2))
end

local function primary_secondary()
  local outputs = all_outputs()
  if #outputs ~= 2 then
    return nil, nil
  end

  local primary = outputs[1]
  local secondary = outputs[2]
  for _, output in ipairs(outputs) do
    if is_internal(output) then
      primary = output
    else
      secondary = output
    end
  end
  return primary, secondary
end

local function niri_output(output, args)
  run(niri .. " msg output " .. q(output) .. " " .. args)
end

local function arrange(kind)
  local primary, secondary = primary_secondary()
  if primary == nil or secondary == nil then
    noctalia.notifyError("display-config", "quick arrangements require exactly two outputs")
    return
  end

  local pw, ph = output_size(primary)
  local sw, sh = output_size(secondary)

  if kind == "extend-right" then
    niri_output(primary, "on")
    niri_output(secondary, "on")
    niri_output(primary, "position set 0 0")
    niri_output(secondary, "position set " .. tostring(pw) .. " 0")
  elseif kind == "extend-left" then
    niri_output(primary, "on")
    niri_output(secondary, "on")
    niri_output(secondary, "position set 0 0")
    niri_output(primary, "position set " .. tostring(sw) .. " 0")
  elseif kind == "stack-above" then
    niri_output(primary, "on")
    niri_output(secondary, "on")
    niri_output(secondary, "position set 0 0")
    niri_output(primary, "position set " .. tostring(math.max(0, math.floor(((sw - pw) / 2) + (1 / 2)))) .. " " .. tostring(sh))
  elseif kind == "stack-below" then
    niri_output(primary, "on")
    niri_output(secondary, "on")
    niri_output(primary, "position set 0 0")
    niri_output(secondary, "position set " .. tostring(math.max(0, math.floor(((pw - sw) / 2) + (1 / 2)))) .. " " .. tostring(ph))
  elseif kind == "external-only" then
    niri_output(primary, "off")
    niri_output(secondary, "on")
    niri_output(secondary, "position set 0 0")
  elseif kind == "internal-only" then
    niri_output(primary, "on")
    niri_output(secondary, "off")
    niri_output(primary, "position set 0 0")
  else
    noctalia.notifyError("display-config", "unknown arrangement: " .. tostring(kind))
    return
  end

  noctalia.notify("display-config", "applied " .. kind)
  update()
end

local function kanshi_switch(profile)
  if profile == nil or profile == "" then
    noctalia.notifyError("display-config", "no kanshi profile configured")
    return
  end
  run_async(kanshictl .. " switch " .. q(profile))
end

function update()
  local outputs = all_outputs()
  local enabled = enabled_outputs()

  if mirror_running() then
    barWidget.setGlyph("screen-share")
    barWidget.setText("mirror")
    barWidget.setColor("error")
    barWidget.setGlyphColor("on_error")
  else
    barWidget.setGlyph("device-desktop")
    barWidget.setText(tostring(#enabled) .. "/" .. tostring(#outputs))
    barWidget.setColor("surface_variant")
    barWidget.setGlyphColor("primary")
  end
end

function onClick()
  local action = cfg("left_click", "wdisplays")
  if action == "mirror" then
    start_mirror()
  elseif action == "extend-right" or action == "extend-left" or action == "stack-above" or action == "stack-below" or action == "external-only" or action == "internal-only" then
    arrange(action)
  elseif action == "kanshi" then
    kanshi_switch(cfg("kanshi_profile", ""))
  else
    run_async(sh .. " -lc " .. q("exec " .. wdisplays))
  end
end

function onRightClick()
  local action = cfg("right_click", "mirror")
  if action == "stop-mirror" then
    stop_mirror()
  elseif action == "wdisplays" then
    run_async(sh .. " -lc " .. q("exec " .. wdisplays))
  else
    start_mirror()
  end
end

function onMiddleClick()
  arrange(cfg("middle_click", "extend-right"))
end

barWidget.setUpdateInterval(5000)
update()
