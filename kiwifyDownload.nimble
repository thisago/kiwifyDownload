# Package

version       = "1.3.0"
author        = "thisago"
description   = "Downloads the kiwify videos from course JSON"
license       = "MIT"
srcDir        = "src"
bin           = @["kiwifyDownload"]
binDir = "build"


# Dependencies

requires "nim >= 1.6.4"
requires "cligen"
requires "util"
