#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
# @deps std
from std/os import `/`, splitFile, walkDirRec, walkDir, pcFile, pcDir
from std/strutils import join, escape, contains
from std/strformat import `&`
from std/sequtils import toSeq
from std/osproc import startProcess, outputStream, errorStream, waitForExit, close, ProcessOption
from std/streams import readAll
# @deps (Optional)
when defined(minilog):
  from minilog as log import nil


#_______________________________________
# @section stdlib: Forward Exports
#_____________________________
export os.`/`
export strformat.`&`
export strutils.contains


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
  stderr  *:string = ""
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
#___________________
proc exec *(cmd :Command) :CommandResult {.discardable.}=
  let process = osproc.startProcess(
    cmd.parts[0],
    args = cmd.parts[1 .. ^1],
    options = {ProcessOption.poUsePath},
  )
  result.stdout = process.outputStream().readAll()
  result.stderr = process.errorStream().readAll()
  result.code = process.waitForExit().u8
  process.close()


#_______________________________________
# @section Configuration
#_____________________________
type NimBackend *{.pure.}= enum c, cpp, js
#___________________
type ConfigFormat * = object
  active  *:bool= false
  cmd     *:Command= Command()
#___________________
type ConfigNim * = object
  bin      *:Path= "nim"
  dir      *:Path= ".nim"
  cache    *:Path= ".nim"
  backend  *:NimBackend= NimBackend.c
  format   *:ConfigFormat= ConfigFormat(cmd: command("nimpretty"))
#___________________
type ConfigC * = object
  bin      *:Path= "zig"
  format   *:ConfigFormat= ConfigFormat(cmd: command("clang-format", "-i"))
#___________________
type ConfigZig * = object
  bin       *:Path= "zig"
  cache     *:Path= ""
  format    *:ConfigFormat= ConfigFormat(cmd: command("zig", "fmt"))
  debugger  *:bool= true
#___________________
type ConfigNonimBin * = object
  nonim  *:Path= "nonim"
  minz   *:Path= "minz"
  minc   *:Path= "minc"
#___________________
type ConfigNonim * = object
  bin    *:ConfigNonimBin= ConfigNonimBin()
  cache  *:Path= "bin/.cache/nonim"
#___________________
type ConfigGLSLUnsafe * = object
  warnings  *:bool= false
#___________________
type ConfigGLSL * = object
  bin     *:Path= "glslc"
  unsafe  *:ConfigGLSLUnsafe= ConfigGLSLUnsafe()
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
  dir    *:ConfigDir    = ConfigDir()
  nim    *:ConfigNim    = ConfigNim()
  c      *:ConfigC      = ConfigC()
  zig    *:ConfigZig    = ConfigZig()
  nonim  *:ConfigNonim  = ConfigNonim()
  glsl   *:ConfigGLSL   = ConfigGLSL()
  log    *:Report       = Report()


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
# @section Helpers: Shell
#_____________________________
from std/envvars import getEnv ; export getEnv
#___________________
proc sh *(cmd:string; args :varargs[string, `$`]) :void {.inline.}=
  let commnd = cmd & " " & args.join(" ")
  echo "Executing command:\n  ", commnd
  try:
    when defined(nimscript): exec commnd
    else:
      if os.execShellCmd(commnd) != 0: raise newException(OSError, "")
  except: raise newException(OSError, &"Failed to run:  {commnd}")
#___________________
proc request *(msg :string; alt :string= "") :string=
  # Report the {@arg msg} to the user
  echo msg
  # Get the line
  result = stdin.readLine()
  if result == "": result = alt
#___________________
proc request *(_:typedesc[char]; msg :string; alt :char= ' ') :char=
  # Report the {@arg msg} to the user
  echo msg
  # Get the character
  var ch = stdin.readChar()
  result = ch
  if result == '\n': result = alt
  # Clear stdin of leftover characters
  while ch != '\n': ch = stdin.readChar()


#_______________________________________
# @section Files & Filesystem Helpers
#_____________________________
func dirname   *(file :Path) :Path= result = os.splitFile(file).dir
func name      *(file :Path) :Path= result = os.splitFile(file).name
func extension *(file :Path) :Path= result = os.splitFile(file).ext
#___________________
func basename  *(file :Path) :Path=
  let (dir, name, ext) = os.splitFile(file)
  result = name & ext
#___________________
func should_skip (
    filters : openArray[Path];
    file    : Path;
  ) :bool=
  for filter in filters:
    if filter in file: return true
#___________________
proc glob *(
    dir     : Path;
    ext     : seq[string]     = @[".c"];
    rec     : bool            = true;
    rel     : bool            = false;
    filters : openArray[Path] = @[];
  ) :seq[Path]=
  ## @descr
  ##  Globs every file in the given folder that has the given ext.
  ##  The resulting list of files will be relative to {@arg dir}
  ##  {@arg ext}     Extension to search for.
  ##  {@arg rec}     Recursive search in all folders and subfolders when true.
  ##  {@arg rel}     Files paths will be relative to {@arg dir} when true.
  ##  {@arg filters} List of paths that will be used to exclude/filter out files that contain any of them
  if rec:
    for file in dir.walkDirRec(relative=rel, skipSpecial=true):
      if filters.shouldSkip(file)  : continue
      if file.splitFile.ext in ext : result.add file
  else:
    for file in dir.walkDir(relative=rel, skipSpecial=true):
      if file.kind != pcFile            : continue
      if filters.shouldSkip(file.path)  : continue
      if file.path.splitFile.ext in ext : result.add file.path
#___________________
proc glob *(
    dir     : Path;
    ext     : string          = ".c";
    rec     : bool            = true;
    rel     : bool            = false;
    filters : openArray[Path] = @[];
  ) :seq[Path]= return dir.glob(@[ext], rec, rel, filters)
  ## @descr Alias to minibuild.glob, but with `ext :string` instead of `ext :seq[string]`
#___________________
proc cp *(src,trg :Path) :void=
  when defined(nimscript) : cpFile(src, trg)
  else                    : os.copyFile(src, trg)
#___________________
proc cpDir *(src,trg :Path) :void=
  when defined(nimscript) : cpDir(src, trg)
  else                    : os.copyDir(src, trg)
#___________________
proc cpDir *(src,trg :string|Path; filter :openArray[string|Path]) :void=
  ## @descr Alternative {@link cpDir} that supports passing a list of {@arg filter} paths to ignore
  for it in src.walkDir:
    if it.path in filter: continue
    if   it.kind == pcFile : cp    it.path, trg/it.path.relativePath(src)
    elif it.kind == pcDir  : cpDir it.path, trg
    else                   : discard
#___________________
proc mv *(src,trg :Path) :void=
  when defined(nimscript) : mvFile(src, trg)
  else                    : os.moveFile(src, trg)
#___________________
proc md *(trg :Path) :void {.inline.}=
  let dir = when trg is Path: trg.string else: trg
  if os.dirExists(dir)    : echo &"Folder already exists. Not creating:  {dir}"; return
  when defined(nimscript) : mkDir(dir)
  else                    : os.createDir(dir)
#___________________
proc ln *(src,trg :Path; symbolic :bool= true) :void {.inline.}=
  ## @descr Creates a symbolic link from {@arg src} to {@arg trg}
  ## @todo Ignores {@arg symbolic} and only creates symbolic links. Should be able to handle both symbolic and hard links
  discard symbolic
  when defined(nimscript) : sh "ln", "-s", src, trg
  else                    : os.createSymlink(src, trg)
#___________________
proc touch *(trg :Path) :void=
  ## @descr Creates the target file if it doesn't exist.
  when defined(nimscript) :
    when defined linux    : exec &"touch {trg}"
    elif defined windows  : exec &"powershell \"Get-Item {trg}\""
  else                    : system.close(system.open(trg, mode = fmAppend))
#___________________
proc rm *(trg :Path)=
  when defined(nimscript) : rmFile(trg)
  else                    : os.removeFile(trg)
#___________________
proc rmDir *(trg :Path)=
  when defined(nimscript) : rmDir(trg)
  else                    : os.removeDir(trg)
#___________________
template withDir *(trg :Path; body :untyped)=
  let prev = paths.getCurrentDir()
  echo "Temporarily entering folder  ", trg
  paths.setCurrentDir(trg)
  body  # Run the code inside the block
  echo "Returning to folder  ", prev.string
  paths.setCurrentDir(prev)


#_______________________________________
# @section Target: Language
#_____________________________
type Language *{.pure.}= enum unknown, nim, c, cpp, zig, minz, minc, glsl, wgsl
#___________________
func From *(_:typedesc[Language]; src :SourceList) :Language=
  if src.len == 0: return Language.unknown
  let extension = src[0].splitFile.ext
  case extension
  of ".nim"                    : Language.nim
  of ".c"                      : Language.c
  of ".cpp", ".cc", ".cxx"     : Language.cpp
  of ".zig"                    : Language.zig
  of ".zm"                     : Language.minz
  of ".cm"                     : Language.minc
  of ".glsl", ".hlsl",
     ".frag", ".vert", ".comp" : Language.glsl
  of ".wgsl"                   : Language.wgsl
  else                         : Language.unknown
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
func dir_src *(D :Dependency; cfg :Config= Config()) :Path=
  let libDir = if D.libDir.len > 0: D.libDir else: cfg.dir.bin/cfg.dir.lib
  result = libDir/D.name/D.path
#___________________
func nim_paths *(D :Dependency; cfg :Config) :seq[string]=
  result.add("--path:" & cfg.dir.bin/cfg.dir.lib/D.name/D.path)
  for dep in D.deps: result.add dep.nim_paths(cfg)
#___________________
func zig_dep_only *(D :Dependency) :seq[string]=
  result.add("--dep")
  result.add(D.name)
#___________________
func zig_module_path *(D :Dependency; cfg :Config) :Path=
  let entry_file = if D.entry.len > 0: D.entry else: D.name & ".zig"
  result = D.dir_src(cfg)/entry_file
#___________________
func zig_collect_transitive_deps (D :Dependency; seen :var seq[string]) :void=
  for subdep in D.deps:
    if subdep.name notin seen:
      zig_collect_transitive_deps(subdep, seen)
      seen.add(subdep.name)
#___________________
func zig_module *(D :Dependency; cfg :Config) :seq[string]=
  var seen :seq[string]
  zig_collect_transitive_deps(D, seen)
  for dep_name in seen:
    result.add("--dep")
    result.add(dep_name)
  result.add("-M" & D.name & "=" & D.zig_module_path(cfg))
#___________________
proc nonim_dep_path (dep :Dependency; cfg :Config) :Path=
  let entry_file = if dep.entry.len > 0: dep.entry else: dep.name & ".zig"
  dep.dir_src()/entry_file
#___________________
proc collect_transitive_dep_names (dep :Dependency; result :var seq[string]) =
  for subdep in dep.deps:
    collect_transitive_dep_names(subdep, result)
    if subdep.name notin result:
      result.add(subdep.name)
#___________________
proc nonim_dep_serialize (dep :Dependency; cfg :Config; cmd :var Command; seen :var seq[string]) =
  if dep.name in seen: return
  for subdep in dep.deps:
    nonim_dep_serialize(subdep, cfg, cmd, seen)
  var subdep_names :seq[string]
  collect_transitive_dep_names(dep, subdep_names)
  cmd.add "--dependency:" & dep.name & ":[" & subdep_names.join(",") & "]:" & dep.nonim_dep_path(cfg)
  seen.add(dep.name)


#_______________________________________
# @section Target
#_____________________________
type Kind *{.pure.}= enum Program, DynamicLib, StaticLib, UnitTest
#___________________
type Target * = object
  kind   :Kind
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
  discard cmd.exec()
#___________________
proc format_exec *(trg :Target; file :Path) :CommandResult {.discardable.}=
  let fmt = case trg.lang
    of Language.c,
       Language.cpp : trg.cfg.c.format
    of Language.zig : trg.cfg.zig.format
    of Language.nim : trg.cfg.nim.format
    else            : return
  if not fmt.active: return
  var cmd = fmt.cmd
  cmd.add(file)
  result = cmd.exec()
#___________________
proc has_modules (trg :Target) :bool=
  if trg.deps.len > 0: return true
  for flag in trg.flags:
    if flag.len > 2 and flag[0] == '-' and flag[1] == 'M': return true
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
  result = Target(kind:kind, src: @[], cfg: cfg, flags: flags, deps: deps)
  result.src.add( result.cfg.dir.src/entry )
  for file in src: result.src.add( result.cfg.dir.src/file )
  result.lang = Language.From(result.src)
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
func unit_test *(
    entry : Path;
    trg   : Path         = "";
    src   : SourceList   = @[];
    cfg   : Config       = Config();
    flags : FlagsList    = default(FlagsList);
    deps  : Dependencies = @[];
  ) :Target= result = minibuild.target(UnitTest, entry, trg, src, cfg, flags, deps)


#_______________________________________
# @section Build & Commands
#_____________________________
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
proc command_zig (trg :Target) :Command=
  result = minibuild.command(trg.cfg.zig.bin)
  case trg.kind
  of DynamicLib,
     StaticLib : result.add "build-lib"
  of Program   : result.add "build-exe"
  of UnitTest  : result.add "test"
  result.add "-femit-bin=" & trg.outDir()/trg.bin()
  if trg.src.len > 1:
    for file in trg.src[1..^1]: result.add(file)
  if trg.cfg.zig.cache.len > 0:
    result.add("--cache-dir", trg.cfg.zig.cache)
    result.add("--global-cache-dir", trg.cfg.zig.cache)
  if trg.cfg.zig.debugger: result.add "-fllvm"
  if trg.has_modules():
    for dep in trg.deps: result.add dep.zig_dep_only()
    result.add "-Mroot=" & trg.entry()
    for dep in trg.deps:
      if dep.path.len > 0 or dep.libDir.len > 0 or dep.entry.len > 0:
        result.add dep.zig_module(trg.cfg)
  else:
    result.add trg.entry()
  for flag in trg.flags: result.add(flag)
#___________________
proc command_nim (trg :Target) :Command=
  result = minibuild.command(trg.cfg.nim.bin)
  result.add($trg.cfg.nim.backend)
  for flag in trg.flags: result.add(flag)
  for dep in trg.deps: result.add(dep.nim_paths(trg.cfg))
  result.add(&"--out:{trg.bin()}")
  result.add(&"--outDir:{trg.outDir()}")
  result.add(trg.entry())
#___________________
proc command_nonim (trg :Target) :Command=
  result = minibuild.command(trg.cfg.nonim.bin.minz)
  result.add "c"
  if trg.cfg.log.level >= ReportMode.verbose: result.add "-v"
  result.add "--binDir:" & trg.outDir()
  result.add "--cacheDir:" & trg.cfg.nonim.cache
  var seen :seq[string]
  for dep in trg.deps: nonim_dep_serialize(dep, trg.cfg, result, seen)
  for flag in trg.flags: result.add flag
  result.add trg.entry()
  result.add trg.bin()
#___________________
proc command_glsl (trg :Target) :Command=
  result = minibuild.command(trg.cfg.glsl.bin)
  # Internally managed flags
  if trg.cfg.log.level <= ReportMode.quiet: result.add "-w"
  if not trg.cfg.glsl.unsafe.warnings: result.add "-Werror"
  # User flags
  for dep  in trg.deps : result.add(&"-I{trg.cfg.dir.bin}/{trg.cfg.dir.lib}/{dep.name}/{dep.path}")
  for flag in trg.flags: result.add flag
  # Source and Output
  result.add trg.src[0]
  result.add "-o"
  result.add trg.src[0] & ".spv"
#___________________
proc build *(
    trg : Target;
    run : bool = false;
  ) :Target {.discardable.}=
  let cmd = case trg.lang
    of Language.c,
       Language.cpp  : trg.command_c()
    of Language.nim  : trg.command_nim()
    of Language.zig  : trg.command_zig()
    of Language.minz : trg.command_nonim()
    of Language.glsl : trg.command_glsl()
    else             : assert false, "minibuild: unsupported language: " & $trg.lang; Command()
  trg.debug("Build Command:\n  " & cmd.join())
  cmd.run()
  if run:
    let binary = trg.binary()
    trg.debug("Running:\n  " & binary)
    discard os.execShellCmd(binary)
  result = trg


#_______________________________________
# @section Source-to-Source Codegen
#_____________________________
func codegen_bin (lang :Language; cfg :Config) :Path=
  ## Compiler binary that owns source-to-source codegen for {@arg lang}.
  case lang
  of Language.minz : cfg.nonim.bin.minz
  of Language.minc : cfg.nonim.bin.minc
  else             : assert false, "minibuild.codegen: unsupported language: " & $lang; ""
#___________________
func codegen_outdir (lang :Language) :Path=
  ## Default output sub-folder (under `cfg.dir.src`) for {@arg lang}'s generated code.
  case lang
  of Language.minz : result = "zig"
  of Language.minc : result = "C"
  else             : assert false, "minibuild.codegen: unsupported language: " & $lang
#___________________
proc codegen *(
    lang  : Language;
    input : Path;
    trg   : Path   = "";
    cfg   : Config = Config();
  ) :CommandResult {.discardable.}=
  ## Source-to-source codegen. Dispatches to the compiler selected by {@arg lang}
  ## (minz handles `.zm` -> Zig, minc handles `.cm` -> C) and generates {@arg input}
  ## (a file or a folder) into {@arg trg}, replicating the input folder structure.
  ## Files merged via `include`, and `.nim` files, are not emitted as separate output.
  ##
  ## {@arg input} `name` is composed from {@arg cfg}`.dir.src` -> `<src>/name`.
  ## {@arg trg} is used as-is when given, and defaults to `<src>/zig` (minz) or
  ## `<src>/C` (minc) when omitted.
  let in_path  = cfg.dir.src/input
  let out_path = if trg.len > 0: trg else: cfg.dir.src/lang.codegen_outdir()
  var cmd = minibuild.command(lang.codegen_bin(cfg))
  cmd.add "cc"
  cmd.add in_path
  cmd.add out_path
  if cfg.log.level >= ReportMode.verbose : cmd.add "--verbose"
  if cfg.log.level <= ReportMode.quiet   : cmd.add "--quiet"
  cfg.log.debug("Codegen Command:\n  " & cmd.join())
  result = cmd.run()


#_______________________________________
# @section mini: Entry Point
#_____________________________
when isMainModule:
  const hello = program("hello.nim")
  hello.build(run=true)

