# Package

version       = "0.1.0"
author        = "Jonas Schubert Erlandsson"
description   = "Liquid template engine with bytecode compiler and VM"
license       = "MIT"
srcDir        = "src"
installDirs   = @["liquid"]

# Dependencies

requires "nim >= 1.6.12"

# Tasks

task clib, "Build C shared library":
  exec "nim c --app:lib -d:release -o:libliquid.dylib src/liquid_c.nim"

