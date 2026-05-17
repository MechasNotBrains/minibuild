#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
# @deps std
from std/os import `/`, splitFile
from std/strutils import join, escape
from std/strformat import `&`
from std/sequtils import toSeq
# @deps (Optional)
when defined(minilog):
  from minilog as log import nil


#_______________________________________
# @section Type Aliases
#_____________________________
type u8         * = system.uint8
type Path       * = system.string
type SourceList * = system.seq[minibuild.Path]
type FlagsList  * = system.seq[string]


#_______________________________________
# @section Command Builder
#_____________________________
type CommandResult * = object
  stdin   *:string = ""
  stdout  *:string = ""
  code    *:u8     = 0
#___________________
type Command * = object
  parts   *:seq[string]   = @[]
  result  *:CommandResult = default(CommandResult)
#___________________
func command *(args :varargs[string, `$`]) :Command= Command(parts: args.toSeq())
#___________________
func join *(cmd :Command) :string= cmd.parts.join(" ")
#___________________
func add *(cmd :var Command; args :varargs[string, `$`]) :var Command {.discardable.}=
  cmd.parts.add args.toSeq()
  result = cmd
#___________________
proc run *(cmd :Command) :CommandResult {.discardable.}=
  result = CommandResult(code: os.execShellCmd(cmd.parts.join(" ")).u8)




#_______________________________________
# @section Configuration
#_____________________________
type NimBackend *{.pure.}= enum c, cpp, js
#___________________
type ConfigNim * = object
  bin      *:Path= "nim"
  dir      *:Path= ".nim"
  cache    *:Path= ".nim"
  backend  *:NimBackend= NimBackend.c
  format   *:ConfigFormat= ConfigFormat(cmd: command("nimpretty"))
#___________________
type ConfigFormat * = object
  active  *:bool= false
  cmd     *:Command= Command()
#___________________
type ConfigC * = object
  bin      *:Path= "zig"
  format   *:ConfigFormat= ConfigFormat(cmd: command("clang-format", "-i"))
#___________________
type ConfigZig * = object
  bin      *:Path= "zig"
  format   *:ConfigFormat= ConfigFormat(cmd: command("zig", "fmt"))
#___________________
type ConfigDir * = object
  root  *:Path= "."
  bin   *:Path= "bin"
  src   *:Path= "src"
  lib   *:Path= ".lib"
  sub   *:Path= ""
#___________________
type ReportMode   *{.pure.}= enum quiet, note, info, verbose, trace
type ReportTarget *{.pure.}= enum cli, logger, all
#___________________
type ReportPrefix * = object
  tool   *:string= "[mini.build]"
  info   *:string= ""
  note   *:string= ""
  error  *:string= " !! ERROR !! "
  debug  *:string= " !! Debug !! "
  warn   *:string= " ! Warning ! "
#___________________
type Report * = object
  level    *:ReportMode   = info
  prefix   *:ReportPrefix = default(ReportPrefix)
  mode     *:ReportTarget = all
#___________________
type Config * = object
  dir  *:ConfigDir  = ConfigDir()
  nim  *:ConfigNim  = ConfigNim()
  c    *:ConfigC    = ConfigC()
  zig  *:ConfigZig  = ConfigZig()
  log  *:Report     = Report()


#_______________________________________
# @section Report
#_____________________________
func to_cli (R :Report; mode :string; args :varargs[string, `$`]) :void=
  debugEcho &"{R.prefix.tool}{mode}{args.join(\" \")}"
#___________________
func trace *(R :Report; args :varargs[string, `$`]) :void=
  if R.mode in {all, logger}:
    when defined(minilog): {.cast(noSideEffect).}: log.trc(args.join(" ").escape) # Logging is always considered safe
  if R.mode in {all, cli}:
    if R.level < ReportMode.trace: return
    R.to_cli(R.prefix.debug, args)
#___________________
func debug *(R :Report; args :varargs[string, `$`]) :void=
  if R.mode in {all, logger}:
    when defined(minilog): {.cast(noSideEffect).}: log.dbg(args.join(" ").escape) # Logging is always considered safe
  if R.mode in {all, cli}:
    if R.level < ReportMode.verbose: return
    R.to_cli(R.prefix.debug, args)


#_______________________________________
# @section Target: Language
#_____________________________
type Language *{.pure.}= enum unknown, nim, c, cpp, zig
#___________________
func From *(_:typedesc[Language]; src :SourceList) :Language=
  if src.len == 0: return Language.unknown
  let extension = src[0].splitFile.ext
  case extension
  of ".nim": Language.nim
  of ".c":   Language.c
  of ".cpp", ".cc", ".cxx": Language.cpp
  of ".zig": Language.zig
  else:      Language.unknown
#___________________
func toLanguage *(src :SourceList) :Language= Language.From(src)
func toLang     *(src :SourceList) :Language= Language.From(src)


#_______________________________________
# @section Dependencies
#_____________________________
const DependencyDefault_Path   *{.strdefine.}= "src"
const DependencyDefault_Entry  *{.strdefine.}= ""
const DependencyDefault_LibDir *{.strdefine.}= ""
#___________________
type Dependency * = object
  name    *:string
  url     *:string
  path    *:Path= DependencyDefault_Path
  entry   *:Path= DependencyDefault_Entry
  libDir  *:Path= DependencyDefault_LibDir
  deps    *:seq[Dependency]= @[]
type Dependencies * = seq[Dependency]
#___________________
func dependency *(
    name  : string;
    url   : string;
    path  : Path         = DependencyDefault_Path;
    entry : Path         = DependencyDefault_Entry;
    deps  : Dependencies = @[];
  ) :Dependency= Dependency(name: name, url: url, path: path, entry: entry, deps: deps,)
#___________________
func paths *(D :Dependency; cfg :Config) :seq[string]=
  result.add("--path:" & cfg.dir.bin/cfg.dir.lib/D.name/D.path)
  for dep in D.deps: result.add dep.paths(cfg)


#_______________________________________
# @section Target
#_____________________________
type Kind *{.pure.}= enum Program, DynamicLib, StaticLib, UnitTest
#___________________
type Target * = object
  src    :SourceList
  trg    :string       = ""
  lang   :Language     = unknown
  cfg    :Config       = default(Config)
  flags  :FlagsList    = default(FlagsList)
  deps   :Dependencies = @[]
#___________________
func srcDir *(trg :Target) :Path= result = trg.cfg.dir.root/trg.cfg.dir.src
func outDir *(trg :Target) :Path= result = trg.cfg.dir.root/trg.cfg.dir.bin/trg.cfg.dir.sub
#___________________
func bin *(trg :Target) :Path= result = case trg.lang
  of nim : trg.trg
  else   : trg.trg
#___________________
func binary *(trg :Target) :Path= result = trg.outDir()/trg.bin()
#___________________
proc entry *(trg :Target) :Path=  trg.src[0]
#___________________
func debug *(trg :Target; args :varargs[string, `$`]) :void= trg.cfg.log.debug(args)
#___________________
proc format *(trg :Target; file :Path) :void=
  let fmt = case trg.lang
    of Language.c,
       Language.cpp : trg.cfg.c.format
    of Language.zig : trg.cfg.zig.format
    of Language.nim : trg.cfg.nim.format
    else            : return
  if not fmt.active: return
  var cmd = fmt.cmd
  cmd.add(file)
  cmd.run()
#___________________
func target *(
    kind  : Kind;
    entry : Path;
    trg   : Path         = "";
    src   : SourceList   = @[];
    cfg   : Config       = Config();
    flags : FlagsList    = default(FlagsList);
    deps  : Dependencies = @[];
  ) :Target=
  result = Target(src: @[], cfg: cfg, flags: flags, deps: deps)
  result.src.add( result.cfg.dir.src/entry )
  for file in src: result.src.add( result.cfg.dir.src/file )
  result.trg = case trg
    of "" : result.src[0].splitFile.name
    else  : trg
#___________________
func program *(
    entry : Path;
    trg   : Path         = "";
    src   : SourceList   = @[];
    cfg   : Config       = Config();
    flags : FlagsList    = default(FlagsList);
    deps  : Dependencies = @[];
  ) :Target= result = minibuild.target(Program, entry, trg, src, cfg, flags, deps)


#_______________________________________
# @section Build & Commands
#_____________________________
proc command_nim (trg :Target; run :bool) :Command=
  result = minibuild.command(trg.cfg.nim.bin)
  result.add($trg.cfg.nim.backend)
  if run: result.add("-r")
  for flag in trg.flags: result.add(flag)
  for dep in trg.deps: result.add(dep.paths(trg.cfg))
  result.add(&"--out:{trg.bin()}")
  result.add(&"--outDir:{trg.outDir()}")
  result.add(trg.entry())
#___________________
proc command_c (trg :Target) :Command=
  result = minibuild.command(trg.cfg.c.bin)
  result.add(case trg.lang
    of Language.cpp : "c++"
    else            : "cc" )
  result.add(trg.flags)
  for dep in trg.deps:  result.add(&"-I{trg.cfg.dir.bin}/{trg.cfg.dir.lib}/{dep.name}/{dep.path}")
  result.add(trg.src)
  result.add(@["-o", &"{trg.outDir()}/{trg.bin()}"])
#___________________
proc build *(trg :Target; run :bool= false) :Target {.discardable.}=
  let cmd = case trg.lang
    of Language.c,
       Language.cpp : trg.command_c()
    of Language.nim : trg.command_nim(run)
    else            : assert false, "minibuild: unsupported language: " & $trg.lang; Command()
  trg.debug("Build Command:\n  " & cmd.join())
  cmd.run()
  if run and trg.lang in {Language.c, Language.cpp}:
    let binary = trg.binary()
    trg.debug("Running:\n  " & binary)
    discard os.execShellCmd(binary)
  result = trg


#_______________________________________
# @section mini: Entry Point
#_____________________________
when isMainModule:
  const hello = program("hello.nim")
  hello.build(run=true)

