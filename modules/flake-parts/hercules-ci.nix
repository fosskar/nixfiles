{
  self,
  inputs,
  ...
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  hci = import "${inputs.nixbot}/herculesCI/effects-lib.nix" { inherit pkgs; };

  repo = "fosskar/nixfiles";
  cloneUrl = "https://codeberg.org/${repo}";
  api = "https://codeberg.org/api/v1/repos/${repo}";

  # inputs that release together share one branch/PR. avoids codeberg's
  # "2 similarly named PRs per hour" spam limit and reduces churn.
  inputGroups = {
    noctalia = [
      "noctalia"
      "noctalia-greeter"
      "noctalia-legacy"
    ];
  };

  # bash assoc-array literal: input -> group (default group = input itself)
  groupMap = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.flatten (
      pkgs.lib.mapAttrsToList (g: members: map (m: "  [${m}]=${g}") members) inputGroups
    )
  );

  # shared script body; per-input grouped lock bumps. PUSH=1 enables
  # branch push + PR create + automerge; otherwise dry (diff only).
  updateScript = ''
    export NIX_CONFIG="experimental-features = nix-command flakes"
    set -u

    gh_conf=""
    [ -n "''${GH_TOKEN:-}" ] && gh_conf="access-tokens = github.com=$GH_TOKEN"
    if [ "''${PUSH:-0}" = 1 ]; then
      token=$(jq -r '.codeberg.data.token' "$HERCULES_CI_SECRETS_JSON")
      gh_conf=$(jq -r '.github.data.config' "$HERCULES_CI_SECRETS_JSON")
      auth="https://nixbot:$token@codeberg.org/${repo}"
    fi
    [ -n "$gh_conf" ] && export NIX_CONFIG="$NIX_CONFIG
    $gh_conf"

    git clone --depth 1 "${cloneUrl}" repo
    cd repo
    git config user.name nixbot
    git config user.email nixbot@noreply.codeberg.org

    declare -A input_group=(
    ${groupMap}
    )

    # POST with 429 backoff (codeberg spam limiter). args: url json
    api_post() {
      local url="$1" data="$2" code body hdr
      hdr=$(mktemp); body=$(mktemp)
      for delay in 5 15 45 120; do
        code=$(curl -sS -D "$hdr" -o "$body" -w '%{http_code}' \
          -H "Authorization: token $token" -H "Content-Type: application/json" \
          -X POST -d "$data" "$url")
        if [ "$code" -lt 400 ]; then cat "$body"; rm -f "$hdr" "$body"; return 0; fi
        if [ "$code" = 429 ]; then
          ra=$(awk 'tolower($1)=="retry-after:"{print $2}' "$hdr" | tr -d '\r' | tail -1)
          echo ":: 429, sleeping ''${ra:-$delay}s" >&2; sleep "''${ra:-$delay}"; continue
        fi
        echo ":: api error $code: $url" >&2; cat "$body" >&2; rm -f "$hdr" "$body"; return 1
      done
      rm -f "$hdr" "$body"; return 1
    }

    mapfile -t roots < <(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[]')

    declare -A group_inputs=()
    for inp in "''${roots[@]}"; do
      g="''${input_group[$inp]:-$inp}"
      group_inputs[$g]+=" $inp"
    done

    for g in $(printf '%s\n' "''${!group_inputs[@]}" | sort); do
      branch="update-input-$g"
      git checkout -q -B "$branch" origin/main
      # shellcheck disable=SC2086
      if ! nix flake update ''${group_inputs[$g]} 2>/dev/null; then
        echo ":: $g - flake update failed, skipping"; git checkout -q -- flake.lock || true; continue
      fi
      if git diff --quiet -- flake.lock; then
        echo ":: $g - no change"; continue
      fi

      if [ "''${PUSH:-0}" != 1 ]; then
        echo ":: $g -> $branch"; git --no-pager diff --stat -- flake.lock
        git checkout -q -- flake.lock; continue
      fi

      git commit -q -m "update $g" -- flake.lock
      git push -q -f "$auth" "HEAD:$branch"

      n=$(curl -sS -H "Authorization: token $token" "${api}/pulls?state=open&limit=50" \
        | jq -r --arg b "$branch" '.[]|select(.head.ref==$b).number' | head -1)
      if [ -z "$n" ]; then
        n=$(api_post "${api}/pulls" \
          "$(jq -nc --arg t "update $g" --arg h "$branch" \
             '{title:$t,head:$h,base:"main",body:"automated flake input update"}')" \
          | jq -r '.number') || { echo ":: $g - PR create failed"; continue; }
      fi
      api_post "${api}/pulls/$n/merge" \
        '{"Do":"squash","merge_when_checks_succeed":true,"delete_branch_after_merge":true}' \
        >/dev/null || echo ":: $g - automerge queued/pending"
      echo ":: $g -> PR #$n"
    done
    exit 0
  '';

  mkUpdateEffect =
    push:
    hci.mkEffect {
      name = "flake-update";
      inputs = [
        pkgs.git
        pkgs.nix
        pkgs.jq
        pkgs.curl
        pkgs.gawk
        pkgs.coreutils
      ];
      effectScript = pkgs.lib.optionalString push "PUSH=1\n" + updateScript;
    };
in
{
  flake.herculesCI = _: {
    onPush.default.outputs = {
      checks = self.checks.x86_64-linux;

      # safe local test: no push, prints per-group lock diff.
      #   nix run github:Mic92/nixbot#nixbot-effects -- run flake-update-dry --rev <full-jj-rev>
      effects.flake-update-dry = mkUpdateEffect false;
    };

    # daily 04:00 UTC: nixbot fires this after a green main build. opens
    # one PR per input (noctalia grouped); each PR gated by checks, automerged.
    onSchedule.flake-update = {
      when = {
        hour = 4;
        minute = 0;
      };
      outputs.effects.update = mkUpdateEffect true;
    };
  };
}
