#_______________________________________
# @section Configuration: Nim
#_____________________________
from "$nim"/compiler/platform import TSystemOS, TSystemCPU, OS, CPU
from "$nim"/compiler/options as nim_opts import
  TOption, TOptions, TGlobalOption, TGlobalOptions, TGCMode, ExceptionSystem,
  Feature, LegacyFeature, TSystemCC, FilenameOption, DefaultGlobalOptions,
  TBackend, backendInvalid
export TOption, TOptions, TGlobalOption, TGlobalOptions
export TGCMode, ExceptionSystem, Feature, LegacyFeature
export TSystemCC, FilenameOption
#___________________
type NimBackend * = nim_opts.TBackend
type NimOptions * = nim_opts.ConfigRef
template defaults *(_:typedesc[NimOptions]) :NimOptions= {.cast(noSideEffect).}: nim_opts.newConfigRef()
#___________________
type ConfigNim * = object
  bin    *:Path= "nim"
  dir    *:Path= ".nim"
  cache  *:Path= ".nim"
  opts   *:NimOptions;
#___________________
func defaults *(_:typedesc[ConfigNim]) :ConfigNim=
  result              = ConfigNim()
  result.opts         = NimOptions.defaults()
  result.opts.backend = backendC
#___________________
func nim_command *(
    cfg   : ConfigNim = ConfigNim();
    entry : Path      = "";
  ) :Command=
  {.cast(noSideEffect).}:
    let defaults = NimOptions.defaults()
  result = minibuild.command(cfg.bin)
  if cfg.opts.backend != backendInvalid                           : result.add($cfg.opts.backend)
  if optRun in cfg.opts.globalOptions                             : result.add("-r")
  for path in cfg.opts.searchPaths                                : result.add("--path:" & path.string)
  for key, val in cfg.opts.symbols                                : result.add("-d:" & key & (if val.len > 0: ":" & val else: ""))
  if optForceFullMake in cfg.opts.globalOptions                   : result.add("--forceBuild:on")
  if cfg.opts.options != defaults.options                         :
    if optStackTrace notin cfg.opts.options                       : result.add("--stackTrace:off")
    if optLineTrace notin cfg.opts.options                        : result.add("--lineTrace:off")
    if optStackTraceMsgs in cfg.opts.options                      : result.add("--stackTraceMsgs:on")
    if optObjCheck notin cfg.opts.options                         : result.add("--objChecks:off")
    if optFieldCheck notin cfg.opts.options                       : result.add("--fieldChecks:off")
    if optRangeCheck notin cfg.opts.options                       : result.add("--rangeChecks:off")
    if optBoundsCheck notin cfg.opts.options                      : result.add("--boundChecks:off")
    if optOverflowCheck notin cfg.opts.options                    : result.add("--overflowChecks:off")
    if optNaNCheck in cfg.opts.options                            : result.add("--nanChecks:on")
    if optInfCheck in cfg.opts.options                            : result.add("--infChecks:on")
    if optAssert notin cfg.opts.options                           : result.add("--assertions:off")
    if optOptimizeSpeed in cfg.opts.options                       : result.add("--opt:speed")
    if optOptimizeSize in cfg.opts.options                        : result.add("--opt:size")
    if optImplicitStatic notin cfg.opts.options                   : result.add("--implicitStatic:off")
    if optTrMacros notin cfg.opts.options                         : result.add("--trmacros:off")
    if optLineDir in cfg.opts.options                             : result.add("--lineDir:on")
    if optHints notin cfg.opts.options                            : result.add("--hints:off")
    if optWarns notin cfg.opts.options                            : result.add("--warnings:off")
  if cfg.opts.globalOptions != defaults.globalOptions             :
    if optExcessiveStackTrace notin cfg.opts.globalOptions        : result.add("--excessiveStackTrace:off")
    if optThreads in cfg.opts.globalOptions                       : result.add("--threads:on")
    if optGenGuiApp in cfg.opts.globalOptions                     : result.add("--app:gui")
    elif optGenDynLib in cfg.opts.globalOptions                   : result.add("--app:lib")
    elif optGenStaticLib in cfg.opts.globalOptions                : result.add("--app:staticlib")
    if optUseNimcache in cfg.opts.globalOptions                   : result.add("--usenimcache")
    if optStdout in cfg.opts.globalOptions                        : result.add("--stdout:on")
    if optUseColors notin cfg.opts.globalOptions                  : result.add("--colors:off")
    if optStyleHint in cfg.opts.globalOptions                     : result.add("--styleCheck:hint")
    elif optStyleError in cfg.opts.globalOptions                  : result.add("--styleCheck:error")
    elif optStyleUsages in cfg.opts.globalOptions                 : result.add("--styleCheck:usages")
    if optShowAllMismatches in cfg.opts.globalOptions             : result.add("--showAllMismatches:on")
    if optCompileOnly in cfg.opts.globalOptions                   : result.add("--compileOnly:on")
    if optNoLinking in cfg.opts.globalOptions                     : result.add("--noLinking:on")
    if optNoMain in cfg.opts.globalOptions                        : result.add("--noMain:on")
    if optGenScript in cfg.opts.globalOptions                     : result.add("--genScript:on")
    if optCDebug in cfg.opts.globalOptions                        : result.add("--debuginfo:on")
    if optEmbedOrigSrc in cfg.opts.globalOptions                  : result.add("--embedsrc:on")
    if optTlsEmulation in cfg.opts.globalOptions                  : result.add("--tlsEmulation:on")
    if optMultiMethods in cfg.opts.globalOptions                  : result.add("--multimethods:on")
    if optHotCodeReloading in cfg.opts.globalOptions              : result.add("--hotCodeReloading:on")
    if optSkipSystemConfigFile in cfg.opts.globalOptions          : result.add("--skipCfg:on")
    if optSkipUserConfigFile in cfg.opts.globalOptions            : result.add("--skipUserCfg:on")
    if optSkipParentConfigFiles in cfg.opts.globalOptions         : result.add("--skipParentCfg:on")
    if optSkipProjConfigFile in cfg.opts.globalOptions            : result.add("--skipProjCfg:on")
    if optGenIndex in cfg.opts.globalOptions                      : result.add("--index:on")
    elif optGenIndexOnly in cfg.opts.globalOptions                : result.add("--index:only")
    if optNoImportdoc in cfg.opts.globalOptions                   : result.add("--noImportdoc:on")
    if optNoNimblePath in cfg.opts.globalOptions                  : result.add("--noNimblePath")
    if optDynlibOverrideAll in cfg.opts.globalOptions             : result.add("--dynlibOverrideAll")
    if optListCmd in cfg.opts.globalOptions                       : result.add("--listCmd")
    if optProduceAsm in cfg.opts.globalOptions                    : result.add("--asm")
    if optBenchmarkVM in cfg.opts.globalOptions                   : result.add("--benchmarkVM:on")
    if optProfileVM in cfg.opts.globalOptions                     : result.add("--profileVM:on")
    if optPanics in cfg.opts.globalOptions                        : result.add("--panics:on")
    if optEnableDeepCopy in cfg.opts.globalOptions                : result.add("--deepcopy:on")
    if optJsBigInt64 notin cfg.opts.globalOptions                 : result.add("--jsbigint64:off")
  if cfg.opts.outDir.string.len > 0                               : result.add("--outdir:" & cfg.opts.outDir.string)
  if cfg.opts.outFile.string.len > 0                              : result.add("--out:" & cfg.opts.outFile.string)
  if cfg.opts.filenameOption != defaults.filenameOption           : result.add("--filenames:" & $cfg.opts.filenameOption)
  if cfg.opts.hintProcessingDots != defaults.hintProcessingDots   : result.add("--processing:" & (if cfg.opts.hintProcessingDots: "dots" else: "off"))
  if cfg.opts.spellSuggestMax != defaults.spellSuggestMax         : result.add("--spellSuggest:" & $cfg.opts.spellSuggestMax)
  if cfg.opts.prefixDir.string.len > 0                            : result.add("--lib:" & cfg.opts.prefixDir.string)
  for module in cfg.opts.implicitImports                          : result.add("--import:" & module)
  for module in cfg.opts.implicitIncludes                         : result.add("--include:" & module)
  if cfg.opts.nimcacheDir.string.len > 0                          : result.add("--nimcache:" & cfg.opts.nimcacheDir.string)
  if cfg.opts.target.targetOS != defaults.target.targetOS         : result.add("--os:" & OS[cfg.opts.target.targetOS].name)
  if cfg.opts.target.targetCPU != defaults.target.targetCPU       : result.add("--cpu:" & CPU[cfg.opts.target.targetCPU].name)
  for passarg in cfg.opts.compileOptionsCmd                       : result.add("--passC:" & passarg)
  if cfg.opts.linkOptionsCmd.len > 0                              : result.add("--passL:" & cfg.opts.linkOptionsCmd)
  if cfg.opts.cCompiler != defaults.cCompiler                     : result.add("--cc:" & $cfg.opts.cCompiler)
  for dir in cfg.opts.cIncludes                                   : result.add("--cincludes:" & dir.string)
  for dir in cfg.opts.cLibs                                       : result.add("--clibdir:" & dir.string)
  for lib in cfg.opts.cLinkedLibs                                 : result.add("--clib:" & lib)
  if cfg.opts.selectedGC != defaults.selectedGC                   : result.add("--mm:" & $cfg.opts.selectedGC)
  if cfg.opts.exc != defaults.exc                                 : result.add("--exceptions:" & $cfg.opts.exc)
  for path in cfg.opts.nimblePaths                                : result.add("--NimblePath:" & path.string)
  if cfg.opts.nimMainPrefix.len > 0                               : result.add("--nimMainPrefix:" & cfg.opts.nimMainPrefix)
  for override in cfg.opts.dllOverrides.keys                      : result.add("--dynlibOverride:" & override)
  if cfg.opts.numberOfProcessors > 0                              : result.add("--parallelBuild:" & $cfg.opts.numberOfProcessors)
  if cfg.opts.verbosity != defaults.verbosity                     : result.add("--verbosity:" & $cfg.opts.verbosity)
  if cfg.opts.errorMax > 0                                        : result.add("--errorMax:" & $cfg.opts.errorMax)
  if cfg.opts.maxLoopIterationsVM != defaults.maxLoopIterationsVM : result.add("--maxLoopIterationsVM:" & $cfg.opts.maxLoopIterationsVM)
  if cfg.opts.maxCallDepthVM != defaults.maxCallDepthVM           : result.add("--maxCallDepthVM:" & $cfg.opts.maxCallDepthVM)
  for feature in cfg.opts.features                                : result.add("--experimental:" & $feature)
  for feature in cfg.opts.legacyFeatures                          : result.add("--legacy:" & $feature)
  if cfg.opts.nimbasePattern != defaults.nimbasePattern           : result.add("--nimBasePattern:" & cfg.opts.nimbasePattern)
  result.add(entry)

