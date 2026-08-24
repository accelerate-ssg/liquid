# Handlebars tine API
# ===================
# Assembles the Handlebars frontend on top of the Pitchfork engine.
# Importing this module registers the tine's truthiness normalizers;
# custom helpers register through the shared filter registry.

import std/[tables, sets]

import ../../bytecode
import ../../values
import ../../vm_types
import ../../vm
import lexer as handlebars_lexer
import compiler as handlebars_compiler

export bytecode, values, vm_types, vm
export handlebars_lexer, handlebars_compiler

proc register_helper*(name: string, handler: Filter) =
  ## Register a Handlebars helper. Helpers are shared-registry filters:
  ## {{helper a b}} calls the filter with value a and args [b].
  register_filter(name, handler)

proc compile_source*(source: string): CompileResult =
  ## Lex and compile Handlebars source to Pitchfork bytecode.
  result = compile(lex_handlebars(source))

proc handlebars_partial_compiler(source: string): CompileResult {.nimcall.} =
  compile_source(source)

proc new_handlebars_vm*(bytecode: seq[Instruction], strings: seq[string],
                        constants: seq[VMValue], root: VMValue,
                        context: ptr Table[string, VMValue],
                        partials: ptr Table[string, string] = nil): VM =
  ## Create a VM wired for Handlebars: partials compile as Handlebars and
  ## the root data value sits at the bottom of the context stack. The
  ## context and partials are borrowed — they must outlive the VM (see
  ## new_vm).
  result = new_vm(bytecode, strings, constants, context, partials)
  result.partial_compiler = handlebars_partial_compiler
  result.ctx_stack.add(root)

proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], root: VMValue, data: Table[string, VMValue],
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render compiled Handlebars bytecode with the given data
  # The VM lives entirely inside this call, so borrowing the parameters
  # is safe.
  var vm = new_handlebars_vm(bytecode, strings, constants, root,
                             unsafeAddr data, unsafeAddr partials)
  result = vm.execute()

proc render_tracked*(bytecode: seq[Instruction], strings: seq[string],
                     constants: seq[VMValue], root: VMValue, data: Table[string, VMValue],
                     partials: Table[string, string] = initTable[string, string]()):
                     tuple[output: string, accessed: HashSet[string]] =
  ## Render compiled Handlebars bytecode and return both the output and the
  ## set of context variable paths accessed during execution.
  var vm = new_handlebars_vm(bytecode, strings, constants, root,
                             unsafeAddr data, unsafeAddr partials)
  vm.track_access = true
  vm.path_stack = @[]
  vm.accessed_paths = initHashSet[string]()
  let output = vm.execute()
  result = (output, vm.accessed_paths)
