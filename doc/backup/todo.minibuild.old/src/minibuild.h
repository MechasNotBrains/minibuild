//:________________________________________________________________________
//  minibuild  |  Copyright (C) Ivan Mar (sOkam!)  |  GNU GPLv3 or later  :
//:________________________________________________________________________
#pragma once
// @deps C stdlib
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

//______________________________________
// @section Configuration Defaults
//____________________________
#if !defined(nb_CC)
#define nb_CC "zig cc"
#endif

#if !defined(nb_dir_source)
#define nb_dir_source "src"
#endif

#if !defined(nb_dir_bin)
#define nb_dir_bin "bin"
#endif


//______________________________________
// @section Buildsystem: Types
//____________________________
typedef char const* nb_String;
#define nb_String_Capacity 1024
typedef nb_String* nb_StringList;
#define _nb_Entry static inline

/// Defines the lists of flags to send when compiling a Target
typedef struct nb_Flags {
  nb_StringList cc;
  nb_StringList link;
} nb_Flags;

/// Defines the type of binary that a Target will produce
typedef enum {
  nb_TargetKind_Program,
  nb_TargetKind_StaticLib,
  nb_TargetKind_Lib,
} nb_TargetKind;

/// Defines a compilation target
typedef struct nb_Target {
  nb_String     target;
  nb_StringList source;
  nb_Flags      flags;
  nb_TargetKind kind;
} nb_Target;

//______________________________________
// @section Buildsystem: Entry Points
//____________________________

/// Orders the buildsystem to compile this Target.
/// Returns the exit code of the build command
int _nb_Entry nb_build(nb_Target const* const trg) {
  char cmd[nb_String_Capacity] = { 0 };
  sprintf(cmd, "%s -o %s", nb_CC, trg->target);
  for (size_t id = 0; trg->source[id] != NULL; ++id) sprintf(cmd, " %s", trg->source[id]);
  return system(cmd);
}

typedef enum {
  nb_Result_Test        = 42,
  nb_Result_NotAProgram = 255,
} nb_Result;

/// Orders the buildsystem to run the resulting binary of this Target.
/// Returns the exit code of the app.
/// Will always return `NotAProgram` and do nothing if the target is not a Program.
int _nb_Entry nb_run(nb_Target const* const trg) {
  if (trg->kind != nb_TargetKind_Program) return nb_Result_NotAProgram;
  return 42;
}

