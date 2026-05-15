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
  dir  *:ConfigDir = ConfigDir()
  nim  *:ConfigNim = ConfigNim()
  log  *:Report    = Report()


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
func From *(_:typedesc[Language]; src :SourceList) :Language= nim
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
func outDir *(trg :Target) :Path= trg.cfg.dir.root/trg.cfg.dir.bin/trg.cfg.dir.sub
func srcDir *(trg :Target) :Path= trg.cfg.dir.root/trg.cfg.dir.src
#___________________
func bin *(trg :Target) :Path= result = case trg.lang
  of nim : trg.trg
  else   : trg.trg
#___________________
proc entry *(trg :Target) :Path=  trg.src[0]
#___________________
func debug *(trg :Target; args :varargs[string, `$`]) :void= trg.cfg.log.debug(args)
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
#___________________
proc build *(trg :Target; run :bool= false) :Target {.discardable.}=
  var cmd = minibuild.command(trg.cfg.nim.bin)
  cmd.add($trg.cfg.nim.backend)
  if run: cmd.add("-r")
  for flag in trg.flags: cmd.add(flag)
  for dep  in trg.deps:  cmd.add(dep.paths(trg.cfg))
  cmd.add(&"--out:{trg.bin()}")
  cmd.add(&"--outDir:{trg.outDir()}")
  cmd.add(trg.entry())
  trg.debug("Build Command:\n  " & cmd.join())
  cmd.run()
  result = trg


#_______________________________________
# @section mini: Entry Point
#_____________________________
when isMainModule:
  const hello = program("hello.nim")
  hello.build(run=true)

