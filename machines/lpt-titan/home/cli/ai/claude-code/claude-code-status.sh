#!/usr/bin/env bash

# read claude-code input
input=$(cat)

# extract model name
model=$(echo "$input" | jq -r '.model.display_name')

# get current directory name
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")

# k8s context (skip if CLAUDE_STATUS_NO_K8S is set)
k8s_context=""
if [ -z "${CLAUDE_STATUS_NO_K8S:-}" ] && command -v kubectl >/dev/null 2>&1; then
  k8s_context=$(timeout 0.5 kubectl config current-context 2>/dev/null || echo "")
fi

# get vcs info (jj preferred, fall back to git)
vcs_info=""
vcs_symbol=""
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
if [ -d "$current_dir/.jj" ]; then
  cd "$current_dir" || exit 1
  # get repo name and parent bookmark/current state
  repo=$(basename "$(git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//')" 2>/dev/null || echo "unknown")
  parent_bookmark=$(jj log -r@- --no-graph --ignore-working-copy --limit 1 -T 'if(bookmarks, bookmarks.join(","), "*")' 2>/dev/null || echo "*")
  current_state=$(jj log -r@ --no-graph --ignore-working-copy --limit 1 -T 'if(empty, "empty", "changes")' 2>/dev/null || echo "unknown")
  vcs_info="$repo:$parent_bookmark/$current_state"
  vcs_symbol="󰘬"
elif [ -d "$current_dir/.git" ]; then
  cd "$current_dir" || exit 1
  repo=$(basename "$(git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//')" 2>/dev/null || echo "unknown")
  branch=$(git branch --show-current 2>/dev/null || echo "unknown")
  vcs_info="$repo:$branch"
  vcs_symbol="󰊢"
else
  vcs_info="no-repo"
  vcs_symbol="󰊢"
fi

# define colors
ORANGE='\033[38;5;208m' # claude orange/brownish
GREEN='\033[32m'
BLUE='\033[34m'
MAGENTA='\033[35m'
RESET='\033[0m'

# build output
output="${ORANGE}󰧑 [${model}]${RESET} | ${GREEN} ${dir}${RESET} | ${MAGENTA}${vcs_symbol} ${vcs_info}${RESET}"
[ -n "$k8s_context" ] && output+=" | ${BLUE}󱃾 ${k8s_context}${RESET}"
echo -e "$output"
