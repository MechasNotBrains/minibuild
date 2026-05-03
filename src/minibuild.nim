#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
from std/os import `/`, splitFile
from std/strutils import join
from std/strformat import `&`
from std/sequtils import toSeq


#_______________________________________
# @section Type Aliases
#_____________________________
type str        * = system.string
type u8         * = system.uint8
type Path       * = str
type SourceList * = system.seq[str]
type FlagsList  * = system.seq[str]


#_______________________________________
# @section Command Builder
#_____________________________
type Command * = object
  parts  :seq[str]= @[]
#___________________
func command *(args :varargs[str, `$`]) :Command= Command(parts: args.toSeq())
#___________________
func join *(cmd :Command) :str= cmd.parts.join(" ")
#___________________
func add *(cmd :var Command; args :varargs[str, `$`]) :var Command {.discardable.}=
  cmd.parts.add args.toSeq()
  result = cmd
#___________________
type CommandResult * = object
  stdin   :str= ""
  stdout  :str= ""
  result  :u8= 0
#___________________
proc run *(cmd :Command) :CommandResult {.discardable.}=
  result = CommandResult(result: os.execShellCmd(cmd.parts.join(" ")).u8)


#_______________________________________
# @section Configuration
#_____________________________
type NimBackend *{.pure.}= enum c, cpp, js
#___________________
type ConfigNim * = object
  bin      :Path= "nim"
  dir      :Path= ".nim"
  cache    :Path= ".nim"
  backend  :NimBackend= NimBackend.c
#___________________
type Log *{.pure.}= enum info, quiet, note, verbose, trace
#___________________
type LogPrefix * = object
  tool   :str= "[mini.build]"
  info   :str= ""
  note   :str= ""
  error  :str= " !! ERROR !! "
  debug  :str= " !! Debug !! "
  warn   :str= " ! Warning ! "
#___________________
type ConfigLog * = object
  level   :Log= Log.info
  prefix  :LogPrefix= default(LogPrefix)
#___________________
func debug *(L :ConfigLog; args :varargs[str, `$`]) :void=
  debugEcho &"{L.prefix.tool}{L.prefix.debug}{args.join(\" \")}"
#___________________
type ConfigDir * = object
  root  :Path= "."
  bin   :Path= "bin"
  src   :Path= "src"
  lib   :Path= ".lib"
  sub   :Path= ""
#___________________
type Config * = object
  dir  :ConfigDir= ConfigDir()
  nim  :ConfigNim= ConfigNim()
  log  :ConfigLog= ConfigLog()


#_______________________________________
# @section Target: Language
#_____________________________
type Language *{.pure.}= enum unknown, nim, c, cpp, zig
#___________________
func From *(_:typedesc[Language]; src :SourceList) :Language= nim
func toLanguage *(src :SourceList) :Language= Language.From(src)
func toLang     *(src :SourceList) :Language= Language.From(src)


#_______________________________________
# @section Target
#_____________________________
type Kind *{.pure.}= enum Program, DynamicLib, StaticLib, UnitTest
#___________________
type Target * = object
  src    :SourceList
  trg    :str       = ""
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
func debug *(trg :Target; args :varargs[str, `$`]) :void= trg.cfg.log.debug(args)
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
  echo "Hello mini.build"
  const hello = program("hello.nim")
  hello.build(run=true)

