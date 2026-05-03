#:_____________________________________________________________
#  mini.build  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0 :
#:_____________________________________________________________
# Package
version     = "0.0.0"
author      = "heysokam"
description = "mini.build | Proving that buildsystems can be Minimal"
license     = "MPL-2.0"
installExt  = @["nim"]
# Binaries
bin         = @["minibuild"]
srcDir      = "src"
binDir      = "bin"
# Dependencies
requires "nim >= 2.0.0"
