# tangled (tngl.sh)

## update handle via api

### 1. get access token

```bash
curl -X POST https://tngl.sh/xrpc/com.atproto.server.createSession \
  -H "Content-Type: application/json" \
  -d '{"identifier": "{HANDLE}", "password": "{PASSWORD}"}'
```

returns json with `accessJwt` field.

### 2. update handle

```bash
curl -X POST https://tngl.sh/xrpc/com.atproto.identity.updateHandle \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {ACCESSJWT}" \
  -d '{"handle": "{NEW_HANDLE}"}'
```

## custom domain handle

to use a custom domain as handle (e.g. `user.example.com`):

### dns txt record

create a TXT record at `_atproto.{HANDLE}`:

```
_atproto.user.example.com  TXT  "did=did:plc:xxxxxxxxxxxxx"
```

get your DID from your profile or the createSession response.

### then update handle

after dns propagates, call updateHandle with your custom domain as the new handle.
