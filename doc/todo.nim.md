# mini.build — Nim Backend TODO

## Command Builder
- [x] Command type with parts list
- [x] `command()` constructor from varargs
- [x] `add()` appends to command
- [x] `run()` executes via `execShellCmd`
- [ ] Capture stdout/stderr (currently only exit code)
- [ ] Error reporting on failed commands

## Configuration
- [x] `ConfigNim` — bin path, cache dir, backend (c/cpp/js)
- [x] `ConfigDir` — root, bin, src, lib, sub
- [x] `ConfigLog` — prefix
- [x] `Report` levels — info, quiet, note, verbose, trace
- [ ] Optimization mode (debug/release/strip/lto)
- [ ] Force recompile flag
- [ ] Verbose/quiet flag passthrough to compiler

## Target
- [x] `Kind` enum — Program, DynamicLib, StaticLib, UnitTest
- [x] `Target` struct with src, trg, cfg, flags, lang
- [x] `outDir` / `srcDir` / `bin` / `entry` path helpers
- [x] `target()` constructor with entry + extra sources
- [x] `program()` alias
- [ ] `dynamicLib()` / `staticLib()` / `unitTest()` aliases
- [ ] Use `Kind` in command builder (--app:lib, --app:staticlib, test runner)
- [ ] Target name auto-detection from entry file (currently broken: `of ""` branch returns `trg` instead of filename)

## Language Detection
- [x] `Language` enum — unknown, nim, c, cpp, zig
- [ ] Auto-detect language from source file extensions (currently hardcoded to nim)

## Nim Command Builder
- [x] Binary + backend subcommand
- [x] `--outDir` / `--out` flags
- [x] `-r` run flag
- [ ] `--nimCache` flag from config
- [ ] `--NimblePath` flag
- [ ] `--path` flags for dependencies
- [ ] `--experimental:strictDefs`
- [ ] Warning/hint strictness flags
- [ ] Optimization flags (`-d:release`, `--opt:speed`, `--debugger:native`)
- [ ] Strip/LTO flags
- [ ] Per-kind flags (--app:lib, --app:staticlib)

## Dependencies
- [ ] Dependency type (name, path, src subdir)
- [ ] Dependency list on Target
- [ ] `--path:` flag generation for Nim dependencies
- [ ] Include path (`-I`) generation for C/C++ dependencies

## Build Flags
- [ ] Default flags per language
- [ ] User flags on Target
- [ ] Internal flags (strict warnings, etc.)
- [ ] Flag merging pipeline (defaults + internal + user)

## Output Paths
- [ ] Create output directories before build
- [ ] Platform-aware binary extensions (.exe on Windows)
- [ ] Subdirectory support for cross-compilation output

## Cross-Compilation
- [ ] System type (os, cpu, abi)
- [ ] Host system detection
- [ ] Cross-compilation detection
- [ ] Zig triple generation
- [ ] Nim `--os:` / `--cpu:` flags
- [ ] ZigCC integration (`--cc:clang --clang.exe=zigcc`)
- [ ] `buildFor(systems)` multi-target builds

## Build Lifecycle
- [x] `build()` compiles the target
- [ ] `run()` as separate step (not just build flag)
- [ ] Logging/reporting during build
- [ ] Error handling on build failure
