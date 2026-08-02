# When to Fake

Substitute dependencies at **system boundaries** only:

- External APIs (registries, payment, mail)
- Databases (sometimes — prefer a scratch instance)
- Time/randomness
- File system (sometimes — prefer a temp dir)
- The network (in-process transport instead of real sockets)

Don't fake:

- Your own modules
- Internal collaborators
- Anything you control

Prefer **hand-written fakes** implementing the seam interface over mocking frameworks: a fake is a tiny real implementation (in-memory map, `httptest.Server`, in-process node) whose behavior you can read; a framework mock is per-test conditional setup that couples the test to call patterns. One fake per seam, reused by every test at that seam.

## Designing for Fakability

At system boundaries, design interfaces that are easy to substitute:

**1. Use dependency injection**

Accept dependencies, don't create them:

```go
// Easy to fake: any HarborAPI works, tests pass an in-memory one
func Reconcile(api HarborAPI, refs []ArtifactRef) error { ... }

// Hard to fake: constructs its own client from the environment
func Reconcile(refs []ArtifactRef) error {
    api := NewClient(os.Getenv("HARBOR_URL"), os.Getenv("HARBOR_TOKEN"))
    ...
}
```

Same rule in Rust: take `impl Trait`/generics or a struct field set by the caller, not a client constructed inside the function.

**2. Prefer narrow, operation-shaped interfaces over generic transports**

Define the seam as the specific operations the caller needs, not a generic request function:

```go
// GOOD: each operation independently fakable, fake is a simple map
type HarborAPI interface {
    ListArtifacts(project, repo string) ([]Artifact, error)
    AddLabel(ref ArtifactRef, label string) error
    RemoveLabel(ref ArtifactRef, label string) error
}

// BAD: faking requires conditional logic on method+path inside the fake
type HarborAPI interface {
    Do(method, path string, body []byte) ([]byte, error)
}
```

The narrow-interface approach means:

- Each fake method returns one specific shape
- No conditional logic in test setup
- Easy to see which operations a test exercises
- The interface documents the real dependency surface
