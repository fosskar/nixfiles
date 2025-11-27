# codeberg actions workflows

this directory contains the ci/cd pipelines for the nixfiles repository, running on codeberg actions (forgejo/gitea).

## workflows

### validate.yml

**triggers:** pushes to main branch only

**what it does:**
- formatting check with treefmt (nixfmt-rfc-style, excludes encrypted files)
- linting with deadnix (find unused nix code)

**parallelization:** runs formatting and linting jobs in parallel for faster feedback

**runtime:** ~2-5 minutes

### release.yml

**triggers:** pushes to main branch only

**what it does:**
- analyzes conventional commits since last release
- determines next version (major/minor/patch)
- generates changelog
- creates git tag
- commits changelog to repository
- optionally creates codeberg release (if FORGEJO_TOKEN secret is set)

**requires:**
- conventional commit format (type(scope): description)
- lowercase commit messages
- at least one commit that triggers a release

**configuration:** uses `.releaserc.codeberg.yml` for semantic-release settings

**runtime:** ~3-5 minutes

### manual-build.yml

**triggers:** manual workflow dispatch only

**what it does:**
- builds nixos configurations on-demand
- useful for pre-deployment validation
- can build a specific machine or all machines

**options:**
- select machine from dropdown (arr, backup, dashboard, etc.)
- or select "all" to build all machines

**use cases:**
- verify builds before deploying to production
- test configuration changes
- troubleshoot build failures

**runtime:**
- single machine: ~5-15 minutes
- all machines: ~30-60 minutes (depending on cache)

## setup requirements

### secrets

no manual secrets required! forgejo actions automatically provides an authentication token (`${{ github.token }}`) for each workflow run with write permissions to the repository.

### permissions

ensure the forgejo actions runner has write permissions:
- settings → actions → general → workflow permissions → read and write permissions

### available runners

codeberg provides shared runners with these labels:
- `codeberg-tiny` - smallest runner (validation jobs)
- `codeberg-small` - small runner (used for validation and release jobs)
- `codeberg-medium` - medium runner (used for build jobs)

nix is installed on-demand using the install-nix-action since codeberg runners don't come with nix pre-installed.

## conventional commits

all commits must follow this format:

```
type(scope): description

[optional body]

[optional footer]
```

**types that trigger releases:**
- `feat`: new feature (minor version bump)
- `fix`: bug fix (patch version bump)
- `perf`: performance improvement (patch version bump)
- `refactor`: code refactor (patch version bump)
- `build`: build system changes (patch version bump)
- `revert`: revert previous commit (patch version bump)
- `improv`: improvement to existing feature (patch version bump)
- `breaking`: breaking change (major version bump)
- `milestone`: major milestone (major version bump)

**types that don't trigger releases:**
- `chore`: maintenance tasks
- `ci`: ci/cd changes
- `docs`: documentation only
- `style`: code style/formatting
- `test`: test changes
- `deps`: dependency updates

**examples:**
```
feat(monitoring): add grafana dashboard for k3s metrics
fix(fileserver): resolve samba permission issues
chore(flake): update nixpkgs input
ci(validate): add parallel job execution
```

**important:** all text must be lowercase (except proper nouns like NixOS, GitHub, etc. in commit body)

## status badges

add these to your repository readme:

```markdown
![validate](https://codeberg.org/simonoscr/nixfiles/actions/workflows/validate.yml/badge.svg)
![release](https://codeberg.org/simonoscr/nixfiles/actions/workflows/release.yml/badge.svg)
```

## troubleshooting

### validation failures

**formatting check fails:**
```bash
nix fmt
git add .
git commit -m "chore: fix formatting"
```

**deadnix check fails:**
```bash
nix run nixpkgs#deadnix -- -e .
# review and remove unused code
```

**flake check fails:**
```bash
nix flake check --print-build-logs
# fix errors reported
```

**conventional commits check fails:**
- ensure commit message starts with lowercase type
- follow format: `type(scope): description`
- use valid types (see above)

### release not triggered

semantic-release only creates releases when:
- commit types trigger a release (feat, fix, etc.)
- commits are on main branch
- commits follow conventional format
- no `[skip ci]` in commit message

### manual build fails

check:
- machine name is correct in flake
- nix evaluation succeeds: `nix eval .#nixosConfigurations.<machine>.config.system.build.toplevel`
- sufficient disk space on runner

## migration from gitlab

gitlab ci (`.gitlab-ci.yml`) is still present as a backup but codeberg actions is now primary.

to fully migrate:
1. ensure codeberg workflows are working
2. verify semantic-release creates proper tags/releases
3. optionally disable gitlab ci pipelines
4. update repository badges/documentation

## local testing

test workflows locally before pushing:

```bash
# format check
nix fmt -- --fail-on-change

# deadnix check
nix run nixpkgs#deadnix -- --fail .

# flake validation
nix flake check --no-build

# pre-commit hooks (includes all checks)
nix develop
pre-commit run --all-files
```

## resources

- codeberg actions docs: https://forgejo.org/docs/latest/user/actions/
- semantic-release: https://semantic-release.gitbook.io/
- conventional commits: https://www.conventionalcommits.org/
