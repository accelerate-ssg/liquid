# Liquid tine API
# ===============
# Assembles the Liquid frontend on top of the Pitchfork engine:
# lexer + compiler produce bytecode; a VM is wired with the Liquid
# runtime tag handlers and a Liquid partial compiler before execution.
#
# Importing this module also registers the built-in Liquid filters.

import std/[tables, sets]

import ../../bytecode
import ../../values
import ../../vm_types
import ../../vm
import lexer as liquid_lexer
import compiler as liquid_compiler
import runtime

# Built-in Liquid filters register themselves on import
import filters/[strings, arrays, numbers, dates, misc]

export bytecode, values, vm_types, vm
export liquid_lexer, liquid_compiler
export runtime

proc compile_source*(source: string, strict: bool = false): CompileResult =
  ## Lex and compile Liquid source to Pitchfork bytecode.
  let sections = lex(source)
  result = compile(sections, source, strict)

proc liquid_partial_compiler(source: string): CompileResult {.nimcall.} =
  compile_source(source, false)

proc new_liquid_vm*(bytecode: seq[Instruction], strings: seq[string],
                    constants: seq[VMValue], data: Table[string, VMValue],
                    partials: Table[string, string] = initTable[string, string]()): VM =
  ## Create a VM wired for Liquid: runtime tag handlers registered and
  ## partials compiled as Liquid.
  result = new_vm(bytecode, strings, constants, data, partials)
  result.register_liquid_runtime()
  result.partial_compiler = liquid_partial_compiler

proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], data: Table[string, VMValue],
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render compiled Liquid bytecode with the given data
  var vm = new_liquid_vm(bytecode, strings, constants, data, partials)
  result = vm.execute()

proc render_tracked*(bytecode: seq[Instruction], strings: seq[string],
                     constants: seq[VMValue], data: Table[string, VMValue],
                     partials: Table[string, string] = initTable[string, string]()):
                     tuple[output: string, accessed: HashSet[string]] =
  ## Render compiled Liquid bytecode and return both the output and the set of
  ## context variable paths that were actually accessed during execution.
  ## Paths use dot notation for properties (e.g. "user.name") and
  ## bracket notation for array indices (e.g. "items[0]").
  var vm = new_liquid_vm(bytecode, strings, constants, data, partials)
  vm.track_access = true
  vm.path_stack = @[]
  vm.accessed_paths = initHashSet[string]()
  let output = vm.execute()
  result = (output, vm.accessed_paths)
