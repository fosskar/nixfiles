# openpgp card ssh key over fido2 and piv

this repo uses the YubiKey OpenPGP card authentication key as the primary SSH key - for SSH login auth and for SSH-format git/jj commit signing - instead of a FIDO2 resident SSH key or a PIV SSH key.

## why the openpgp authentication key

### one stable ssh key across backup yubikeys

multiple YubiKeys hold the same identity, so a lost key is not a lockout.

the OpenPGP card allows importing the same authentication subkey onto several YubiKeys. that produces one stable SSH public key, and any enrolled YubiKey unlocks the same identity. one entry in forge SSH keys, `authorized_keys`, git signing config, and allowed-signers files.

FIDO2 resident SSH keys cannot do this: each key generates its own credential, so every backup YubiKey is a different SSH public key that must be added everywhere. more state, more places to get it wrong.

### gpg-agent gives usable pin caching

through `gpg-agent`, the card behaves like an SSH agent with PIN cache TTLs, so daily git/SSH work does not re-prompt for the PIN on every operation. this is the decisive usability difference against PIV.

### one cached pin covers secret decryption too

clan/sops secrets are encrypted to both the OpenPGP (PGP) recipient and the PIV `age-plugin-yubikey` recipient. decrypting through the PGP recipient goes via `gpg-agent`, so the same cached PIN that covers SSH and signing also covers secret decryption. the PIV/age path has no agent and re-prompts on every single decrypt.

the payoff is batch deploys: updating many machines in one run decrypts many secrets, but with the gpg path the PIN is requested at most once per cache window instead of once per secret per machine. unattended fleet deploys become possible.

this depends on sops using the PGP path rather than the PIV age identity, controlled by not exporting `SOPS_AGE_KEY_CMD` (see `.envrc`). the age recipient stays baked into every secret file as a portable fallback for machines where the gpg key is not set up.

### ssh signatures over openpgp signatures for git

git signs with `gpg.format = ssh`, not OpenPGP signatures. this keeps the private key on the YubiKey while avoiding the GPG trust model for commit verification: forges already understand SSH signing keys, and the same key style is used for SSH access. local verification needs an allowed-signers file, simpler than OpenPGP trust here.

## technical comparison

| aspect                | openpgp auth key (chosen)                      | fido2 resident ssh key                       | piv ssh key                                       |
| --------------------- | ---------------------------------------------- | -------------------------------------------- | ------------------------------------------------- |
| same key on many keys | yes - import one auth subkey onto each yubikey | no - each key is a distinct credential       | yes in theory - same key material importable      |
| linux ssh agent path  | `gpg-agent` ssh support, first-class           | `ssh-agent`/`ssh-sk`, per-key identities     | needs opensc/pkcs#11; `yubikey-agent` doesn't fit |
| pin prompts           | cached via `gpg-agent` ttl                     | touch/pin per policy                         | prompts on nearly every use, even pin policy none |
| private key location  | hardware-backed on card                        | hardware-backed                              | hardware-backed                                   |
| git signing fit       | ssh-format signing, forge-native               | ssh-format signing, but multi-key public set | ssh-format signing, but agent/pin friction        |

net effect: the OpenPGP auth key is the only option that combines one reusable identity across backup keys with low-friction PIN caching on Linux.

## security

hardware keys defend two distinct threats, and this setup relies on both:

- remote compromise / malware on the host: the auth, signature, and decryption keys live on the card and are non-extractable. a compromised host cannot exfiltrate the private key. at worst it can use the key while the card is inserted and the PIN is cached - it never gets the key itself.
- physical theft or loss: a stolen card is useless without the user PIN. the OpenPGP applet blocks after a small number of wrong PIN attempts (3 by default), so the PIN cannot be brute-forced. the device is inert to a thief.

because of that, losing a YubiKey is not an emergency. response is rotation, not panic: generate fresh auth/sign/enc subkeys, re-publish the new public key, and update `authorized_keys`, forge SSH keys, and allowed-signers. that invalidates the lost device's identity everywhere it was trusted. the non-extractable + PIN-locked properties mean nothing is exposed in the window before rotation.

accepted security tradeoff - touch off, long PIN cache: touch policy is off on all slots and the SSH PIN cache TTL is long (24h, 7d max). once the PIN is entered, an unlocked session with the card inserted can sign and authenticate without a touch or a re-prompt for the cache window. this moves the security boundary from each operation to the unlocked host session - convenience over per-operation presence. enabling a touch policy (`ykman openpgp keys set-touch`) or shortening the TTL would harden this if the host session is no longer trusted as the boundary.

## accepted tradeoffs

- the OpenPGP card stack is more complex than an on-disk SSH key; on-disk would be simpler but loses hardware-backed storage.
- the same authentication key serves both SSH login and git/jj signing - weaker separation than a dedicated signing key. accepted for the identity/backup/caching benefits above.
- SSH-format git signature verification needs an allowed-signers file for local checks.
- the OpenPGP signature slot is left unused for git signing; commits sign via the authentication slot exposed as SSH (`gpg.format = ssh`). the decryption slot stays available for SOPS PGP recipients, separate from the `age-plugin-yubikey` identity.

## repo wiring

- `modules/nixos/hardware/yubikey/gpg-ssh.nix`: `gpg-agent` ssh support, disables the plain ssh agent, gpg smartcards, publishes `id_yubikey.pub` via clan vars.
- `modules/home-manager/cli/git.nix`: `programs.git.signing.format = "ssh"`, sign by default.
- `users/simon/signing.nix`: per-user `ssh-ed25519` signing key for git and jj.
- `modules/home-manager/system/gpg.nix`: general `gpg`/`gpg-agent` aspect (hardened settings, pinentry, non-ssh cache ttls).
- `modules/home-manager/system/yubikey-gpg.nix`: `yubikeyGpg` aspect with the card pubkey, `disable-ccid`, ssh support, and ssh cache ttls; imported alongside `gpg` by `users/simon`.
- `.envrc`: leaves `SOPS_AGE_KEY_CMD` unset so secret decryption uses the cached gpg path.
