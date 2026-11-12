---
description: Go development patterns, tooling (mise, gofmt, go vet, staticcheck), naming, structure, error handling and testing conventions. Auto-loads when working with .go files.
paths: "**/*.go"
---

# Go Development Patterns

## Language Preferences

- **Go Version**: latest stable, pinned per project in `mise.toml` and in `go.mod`'s `go` line
- **Code Style**: whatever `gofmt` outputs; no manual line-length rule
- **Standard library first**: add a dependency only when the standard library has no
  reasonable equivalent
- **No cgo**: prefer pure-Go dependencies so a plain `go build` works everywhere

## Tools & Environment

**Toolchain**: `mise`, one `mise.toml` at the project root:

```toml
[tools]
go = "1.27"
"go:honnef.co/go/tools/cmd/staticcheck" = "latest"
```

**Code Quality**, run all before every commit:

```bash
gofmt -l .           # formatting: must print nothing
go vet ./...         # suspicious constructs
staticcheck ./...    # bugs, dead code, simplifications
go test ./...        # tests
```

When a project has several steps (build, generate, check), put them in `scripts/check.sh`
rather than repeating them in docs.

**Dependencies**: `go mod tidy` after adding or removing an import; commit `go.sum`.

## Preferred Libraries

- **CLI**: `github.com/spf13/cobra`
- **SQLite**: `modernc.org/sqlite` (pure Go)
- **PostgreSQL**: `github.com/jackc/pgx/v5`, queries generated with `sqlc` when there are many
- **Config**: flags and environment variables first; TOML file only when needed
- **Logging**: `log/slog`
- **Concurrency**: `golang.org/x/sync/errgroup`

## Naming Conventions

- **Packages**: short, lowercase, one word, no underscores (`store`, `render`); named by what
  they provide, never `util`, `common` or `helpers`
- **Files**: `snake_case.go`, tests beside them as `snake_case_test.go`
- **Exported identifiers**: `PascalCase`; unexported: `camelCase`
- **Initialisms**: keep one case (`userID`, `HTTPClient`, `parseURL`)
- **No stutter**: `store.Open`, not `store.OpenStore`
- **Interfaces**: one method → method name + `er` (`Reader`); otherwise named by role
- **Constants**: `camelCase` or `PascalCase` like any identifier, never `SCREAMING_SNAKE_CASE`
- **Abbreviations**: descriptive names everywhere, except this closed list of Go idioms:
  - `ctx` (`context.Context`), `err` (`error`), `ok` (comma-ok results)
  - one- or two-letter method receivers named after the type (`func (s *Store)`)
  - `i`, `j` as loop indexes in loops of a few lines

## Project Structure

```
project/
├── cmd/<binary>/          # main package, one folder per binary: flags, wiring, exit codes
├── internal/<package>/    # all other code; not importable by other modules
├── testdata/              # fixtures and golden files, ignored by the go tool
├── scripts/               # check.sh and other project scripts
├── tmp/                   # temporary files (testing, scratch)
├── go.mod
└── mise.toml
```

- Organize packages by domain (`store`, `render`), NOT by technical layer (`models`,
  `services`)
- Start with few packages; split one only when it has two clear responsibilities
- No `pkg/` folder: code is `internal/` unless another module really imports it
- `main` stays thin: parse input, build dependencies, call `internal/`, map errors to exit codes
  in one place

## Programming Paradigms

**Plain functions and structs first**:
- Functions over methods when there is no state to hold
- Structs hold data; methods only when they need the struct's fields
- Make the zero value useful, or provide one constructor `NewX` that validates
- Composition through fields; embedding only to promote a small, intended method set

**Interfaces**:
- Define an interface where it is consumed, not where it is implemented
- Accept interfaces, return concrete types
- No interface with a single implementation: wait for the second one

**Generics**: only to remove real duplication across types, never in advance.

**Concurrency** (only when there is a measured or obvious need):
- `context.Context` as the first parameter of anything that blocks or does I/O
- `errgroup` over raw goroutines and `sync.WaitGroup` when errors matter
- The goroutine's creator is responsible for stopping it; no fire-and-forget

## Error Handling

- Return errors; never `panic` for expected failures
- Wrap with context: `fmt.Errorf("open store %s: %w", path, err)`; message is lowercase, no
  trailing punctuation
- Sentinel errors (`var ErrNotFound = errors.New("not found")`) or typed errors for callers that
  branch; check with `errors.Is` / `errors.As`, never by comparing strings
- Handle an error once: either return it or log it, not both
- Validate input at the boundary (`cmd/`, HTTP handlers) with descriptive messages
- `defer` cleanup right after acquiring a resource; check the error of `Close` on writes

## Testing Patterns

- Standard `testing` package only, no assertion library
- Table-driven tests with `t.Run` subtests named by scenario
- Fixtures and golden files in `testdata/`; regenerate golden files with an `-update` flag
- Real dependencies, no mocks: a temporary SQLite file (`t.TempDir()`), a real local
  PostgreSQL, a real HTTP server from `net/http/httptest`
- `t.Helper()` in helpers, `t.Cleanup()` for teardown, `t.Parallel()` when tests share nothing
- Descriptive test names: `TestParseDuration`, subtests `"rejects negative values"`
- Check for races with `go test -race ./...` when the code uses goroutines

## Performance Considerations

- Measure before optimizing: benchmarks (`func BenchmarkX(b *testing.B)`) and `pprof`
- Preallocate slices and maps when the size is known
- Stream large inputs (`io.Reader`, `bufio.Scanner`) instead of loading them whole
