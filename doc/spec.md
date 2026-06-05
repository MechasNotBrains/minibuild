## Config
### Documentation
- [ ] must have documentation comments on every tool exposed to the user
- [ ] must have an automated documentation generator that turns doc-comments into a documentation website
- [ ] must have an automated documentation generator that turns doc-comments into a documentation folder with markdown files
### Logging
- [ ] must have a .log=trace    : enum.value that makes every command fully verbose, including the internal compiler commands, and applies verbose
- [ ] must have a .log=verbose  : enum.value option that makes every command verbose by reporting what is being run, without making the output noisy
- [ ] must have a .log=default  : enum.value (omitted) that reports to cli normally, giving back info+note messages to the user
- [ ] must have a .log=quiet    : enum.value that makes the default output silent, only giving back minimal note messages to the user
- [ ] must have a .tool.prefix  : string added at the beginning of every log command (eg: `[mini.build]`)
- [ ] must have a .tool.debug   : string added after prefix to log commands (eg: " !! debug !!" -> `[mini.build] !! debug !!`) and is used by verbose level reports
- [ ] must have a .tool.warning : string added after prefix to log commands (eg: " ! warning !" -> `[mini.build] ! warning !`) and is used by warning level reports
- [ ] must have a .tool.info    : string added after prefix to log commands (eg: "" -> `[mini.build]`) and is used by info level reports
- [ ] must not use any .tool prefixes when reporting log.note commands
- [ ] must report compilation progress to cli with (eg: `.` -> `......` for every step (or every second) of the compilation process without adding a newline or a prefix to each step
### Commands
- [ ] must have a Command builder that builds/holds arbitrary cli commands that can be run by the user when requested
- [ ] must have a Command.run() helper that runs the given command on shell-like (aka inherit) mode
- [ ] must have a Command.exec() helper that runs the given command and stores stdin/stdout/returncode, with an (omittable) option to run in shell-like mode
- [ ] must have a Command.dir that allows the user to change which folder will be used as cwd when running the command
### Nim
- [ ] must have a .nim.systemBin : bool (default: true) that uses `.dir.bin`/`.nim.dir`/`.nim.bin` (eg: `./bin/.nim/bin/nim`) when false, and `.nim.bin` (eg: `nim` when true)
- [ ] must have a .command() nim Command builder helper (with omittable/sane default arguments, and configurable properties) that can express the full feature set of the `nim` CLI tool
