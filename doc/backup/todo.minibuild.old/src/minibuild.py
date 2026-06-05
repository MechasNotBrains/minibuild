#:________________________________________________________________________
#  minibuild  |  Copyright (C) Ivan Mar (sOkam!)  |  GNU GPLv3 or later  :
#:________________________________________________________________________


#_______________________________________
# @section Target
#_____________________________
class BuildTarget:
  src  :list[str]= []
  trg  :str
Program = BuildTarget

#_______________________________________
# @section Command
#_____________________________
def zigcc (
    cc  : str,
    trg : BuildTarget,
  ) ->list[str]:
  result = []
  result.append("zig")
  result.append(cc)
  # Add source code
  result.extend(trg.src)
  # Add Flags
  result.append("-o")
  result.append(trg)
  # Return the result
  return result
#___________________
def C   (trg :BuildTarget) ->list[str]: return zigcc("cc", trg)
def Cpp (trg :BuildTarget) ->list[str]: return zigcc("c++", trg)

