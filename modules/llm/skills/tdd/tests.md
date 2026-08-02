# Good and Bad Tests

Examples below use Rust and Go; the rules are language-free.

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```rust
// GOOD: Tests observable behavior through the public interface
#[test]
fn reconcile_imports_newer_remote_session() {
    let (local, remote) = fixture_snapshots();
    let actions = reconcile(&local, &remote);
    assert_eq!(actions, vec![Action::Import(remote_session_id())]);
}
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```go
// BAD: Asserts on how the work is done, not what it achieves
func TestReconcileCallsAddLabel(t *testing.T) {
    fake := &fakeHarbor{}
    Reconcile(fake, refs)
    if fake.addLabelCalls != 3 { // breaks when batching changes, behavior identical
        t.Fatalf("want 3 calls, got %d", fake.addLabelCalls)
    }
}

// GOOD: Asserts the observable end state at the seam
func TestReconcileLabelsRunningImages(t *testing.T) {
    fake := newFakeHarbor(unlabeled(refs))
    Reconcile(fake, refs)
    if !fake.allLabeled(refs) {
        t.Fatal("running images not labeled")
    }
}
```

Red flags:

- Mocking internal collaborators
- Testing private functions
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of the interface

```rust
// BAD: Bypasses the interface to verify — reads the store file directly
#[test]
fn import_writes_session() {
    engine.apply(Action::Import(id));
    let raw = std::fs::read_to_string(store_path(id)).unwrap(); // side channel
    assert!(raw.contains("session"));
}

// GOOD: Verifies through the interface
#[test]
fn imported_session_is_retrievable() {
    engine.apply(Action::Import(id));
    assert!(engine.sessions().any(|s| s.id == id));
}
```

**Tautological tests**: Expected value restates the implementation, so the test passes by construction.

```go
// BAD: Expected value is recomputed the way the code computes it
got := Total(items)
want := 0
for _, i := range items { want += i.Price } // same algorithm as Total
if got != want { t.Fail() }

// GOOD: Expected value is an independent, known literal
if got := Total(items); got != 15 {
    t.Fatalf("want 15, got %d", got)
}
```

The same rule catches nix eval assertions: assert the option against a hand-written expected value, never against a re-evaluation of the same expression.
