#!/usr/bin/env bash

# read claude-code input
input=$(cat)

# extract model name
model=$(echo "$input" | jq -r '.model.display_name')

# get current directory name
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")

# get kubernetes context (handle errors gracefully)
k8s_context=""
if command -v kubectl >/dev/null 2>&1; then
  k8s_context=$(kubectl config current-context 2>/dev/null || echo "none")
else
  k8s_context="none"
fi

# get vcs info (jj preferred, fall back to git)
vcs_info=""
vcs_symbol=""
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
if [ -d "$current_dir/.jj" ]; then
  cd "$current_dir" || exit 1
  # get jj bookmark
  jj_bookmark=$(jj log -r@ --no-graph --ignore-working-copy --limit 1 -T 'if(bookmarks, bookmarks.join(","), "")' 2>/dev/null || echo "")
  repo=$(basename "$(git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//')" 2>/dev/null || echo "unknown")
  
  # build vcs_info with asterisk for unbookmarked changes
  if [ -n "$jj_bookmark" ]; then
    vcs_info="$repo:$jj_bookmark"
  else
    vcs_info="$repo:*"
  fi
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

# output formatted status with colors
echo -e "${ORANGE}󰧑 [${model}]${RESET} | ${GREEN} ${dir}${RESET} | ${BLUE}󱃾 ${k8s_context}${RESET} | ${MAGENTA}${vcs_symbol} ${vcs_info}${RESET}"
