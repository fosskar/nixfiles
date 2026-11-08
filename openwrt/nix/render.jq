# builds cfg for apply.uc from the nix-generated config ($c) and decrypted secrets ($s)
def secrets: $s[0];
def hash: $ENV.ROOT_PASSWORD_HASH | if . == "" then null else . end;
def sub:
  if type == "string" then
    gsub("@(?<k>[A-Za-z0-9_]+)@"; .k as $k | if secrets | has($k) then secrets[$k] | tostring else error("unknown secret @\($k)@") end)
  elif type == "array" then map(sub)
  elif type == "object" then map_values(sub)
  else . end;

$c[0]
| if .root_password_secret != null and hash == null then error("root_password_secret is set but ROOT_PASSWORD_HASH is empty") else . end
| .uci.settings |= sub
| .files |= map(.content |= sub)
| del(.root_password_secret)
| . + {
    mode: $mode,
    root_password_hash: hash,
    # short values such as "1" would redact unrelated output
    redact: ([secrets[] | tostring | select(length >= 4)] + (if hash then [hash] else [] end))
  }
| . + $overrides
