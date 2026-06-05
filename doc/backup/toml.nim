#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
from std/strutils import strip, startsWith, endsWith, split, parseInt, parseBool, contains
from std/tables import Table, `[]`, `[]=`, contains, initTable, pairs

export `[]`, contains

type TomlValue *{.pure.}= enum string, integer, boolean, array
type TomlEntry * = object
  case kind *:TomlValue
  of TomlValue.string  : string_value  *:string
  of TomlValue.integer : integer_value *:int
  of TomlValue.boolean : boolean_value *:bool
  of TomlValue.array   : array_value   *:seq[string]

type TomlSection * = Table[string, TomlEntry]
type Toml * = Table[string, TomlSection]


proc parse_value (raw :string) :TomlEntry=
  let value = raw.strip()
  if value.startsWith("\"") and value.endsWith("\""):
    return TomlEntry(kind: TomlValue.string, string_value: value[1..^2])
  if value.startsWith("[") and value.endsWith("]"):
    let inner = value[1..^2]
    var items :seq[string]= @[]
    for item in inner.split(","):
      let trimmed = item.strip()
      if trimmed.len == 0: continue
      if trimmed.startsWith("\"") and trimmed.endsWith("\""):
        items.add(trimmed[1..^2])
      else:
        items.add(trimmed)
    return TomlEntry(kind: TomlValue.array, array_value: items)
  if value == "true" or value == "false":
    return TomlEntry(kind: TomlValue.boolean, boolean_value: value.parseBool())
  try:
    return TomlEntry(kind: TomlValue.integer, integer_value: value.parseInt())
  except ValueError:
    return TomlEntry(kind: TomlValue.string, string_value: value)


proc parse *(content :string) :Toml=
  result = initTable[string, TomlSection]()
  var current_section = ""
  result[current_section] = initTable[string, TomlEntry]()
  for line in content.split("\n"):
    let trimmed = line.strip()
    if trimmed.len == 0: continue
    if trimmed.startsWith("#"): continue
    if trimmed.startsWith("[") and trimmed.endsWith("]"):
      current_section = trimmed[1..^2]
      if current_section notin result:
        result[current_section] = initTable[string, TomlEntry]()
      continue
    if trimmed.contains("="):
      let parts = trimmed.split("=", maxsplit=1)
      if parts.len == 2:
        let key = parts[0].strip()
        let value = parse_value(parts[1])
        result[current_section][key] = value


proc parse_file *(path :string) :Toml=
  let content = readFile(path)
  return parse(content)


proc get_string *(section :TomlSection; key :string; fallback :string= "") :string=
  if key in section:
    let entry = section[key]
    if entry.kind == TomlValue.string: return entry.string_value
  return fallback

proc get_integer *(section :TomlSection; key :string; fallback :int= 0) :int=
  if key in section:
    let entry = section[key]
    if entry.kind == TomlValue.integer: return entry.integer_value
  return fallback

proc get_boolean *(section :TomlSection; key :string; fallback :bool= false) :bool=
  if key in section:
    let entry = section[key]
    if entry.kind == TomlValue.boolean: return entry.boolean_value
  return fallback

proc get_array *(section :TomlSection; key :string; fallback :seq[string]= @[]) :seq[string]=
  if key in section:
    let entry = section[key]
    if entry.kind == TomlValue.array: return entry.array_value
  return fallback

