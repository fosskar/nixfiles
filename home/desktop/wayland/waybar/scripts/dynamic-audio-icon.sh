#!/bin/bash
current_sink=$(pactl get-default-sink)
volume=$(pactl get-sink-volume "$current_sink" | grep -Po '\d+%' | head -1)

if [[ $current_sink == *"Focusrite_Scarlett"* ]]; then
    icon="󰋎" # Example icon for Focusrite
elif [[ $current_sink == *"SteelSeries_Arctis_Nova_Pro_Wireless"* ]]; then
    icon="󰋋" # Example icon for SteelSeries
else
    icon="" # Default icon
fi

echo "$icon $volume"
