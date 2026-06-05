#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
# @deps std
from std/os import `/`, splitFile
from std/strutils import join, escape
from std/strformat import `&`
from std/sequtils import toSeq


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
func cli_report (L :Report; mode :string; args :varargs[string, `$`]) :void=
  debugEcho &"{L.prefix.tool}{mode}{args.join(\" \")}"
#___________________
func trace *(L :Report; args :varargs[string, `$`]) :void=
  if L.mode in {all, logger}:
    when defined(minilog): {.cast(noSideEffect).}: log.trc(args.join(" ").escape) # Logging is always considered safe
  if L.mode in {all, cli}:
    if L.level < ReportMode.trace: return
    L.cli_report(L.prefix.debug, args)
#___________________
func debug *(L :Report; args :varargs[string, `$`]) :void=
  if L.mode in {all, logger}:
    when defined(minilog): {.cast(noSideEffect).}: log.dbg(args.join(" ").escape) # Logging is always considered safe
  if L.mode in {all, cli}:
    if L.level < ReportMode.verbose: return
    L.cli_report(L.prefix.debug, args)
#___________________
type Config * = object
  dir  *:ConfigDir = ConfigDir()
  nim  *:ConfigNim = ConfigNim()
  log  *:Report    = Report()


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
# @section Target
#_____________________________
type Kind *{.pure.}= enum Program, DynamicLib, StaticLib, UnitTest
#___________________
type Target * = object
  src    :SourceList
  trg    :string    = ""
  cfg    :Config    = default(Config)
  flags  :FlagsList = default(FlagsList)
  lang   :Language  = unknown
#___________________
func outDir *(trg :Target) :Path= trg.cfg.dir.root/trg.cfg.dir.bin/trg.cfg.dir.sub
func srcDir *(trg :Target) :Path= trg.cfg.dir.root/trg.cfg.dir.src
#___________________
func bin *(trg :Target) :Path= result = case trg.lang
  of nim : trg.cfg.dir.root/trg.cfg.dir.bin/trg.trg
  else   : trg.trg
#___________________
proc entry *(trg :Target) :Path=  trg.src[0]
#___________________
func debug *(trg :Target; args :varargs[string, `$`]) :void= trg.cfg.log.debug(args)
#___________________
func target *(
    kind  : Kind;
    entry : Path;
    trg   : Path       = "";
    src   : SourceList = @[];
    cfg   : Config     = Config();
  ) :Target=
  result = Target(src: @[], cfg: cfg)
  result.src.add( result.cfg.dir.src/entry )
  for file in src: result.src.add( result.cfg.dir.src/file )
  result.trg = case trg
    of "" : result.src[0].splitFile.name
    else  : trg
#___________________
func program *(
    entry : Path;
    trg   : Path       = "";
    src   : SourceList = @[];
    cfg   : Config     = Config();
  ) :Target= result = minibuild.target(Program, entry, trg, src, cfg)
#___________________
proc build *(trg :Target; run :bool= false) :Target {.discardable.}=
  var cmd = minibuild.command(trg.cfg.nim.bin)
  cmd.add($trg.cfg.nim.backend)
  if run: cmd.add("-r")
  cmd.add(&"--outDir:{trg.outDir()}")
  cmd.add(&"--out:{trg.bin()}")
  cmd.add(trg.entry())
  trg.debug("Build Command:\n  " & cmd.join())
  cmd.run()
  result = trg


#_______________________________________
# @section mini: Entry Point
#_____________________________
when isMainModule:
  var hello = program("hello.nim")
  hello.cfg.log.level = verbose
  hello.build(run=true)

  import ../toml
  let config = toml.parse_file("minibuild.toml")
  let build_section = config["build"]
  let nim_section = config["nim"]

  echo "entry:   ", build_section.get_string("entry")
  echo "outdir:  ", build_section.get_string("outdir")
  echo "run:     ", build_section.get_boolean("run")
  echo "backend: ", nim_section.get_string("backend")
  echo "mm:      ", nim_section.get_string("mm")
  echo "opt:     ", nim_section.get_string("opt")
  echo "define:  ", nim_section.get_array("define")
  echo "path:    ", nim_section.get_array("path")
  echo "threads: ", nim_section.get_boolean("threads")


