#!/usr/bin/env bash
# --wait
# -----
set -eu
echo "serves as the entry point — pivotal # not a comment"
echo 'I hope this helps # not a comment'
echo "$#" "${#BASH_SOURCE[@]}"
x=foo#pivotal
echo "$x"
cat <<EOT
# pivotal — I hope this helps
EOT
