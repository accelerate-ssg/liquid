# Mustache tine API
# =================
# Assembles the Mustache frontend on top of the Pitchfork engine.
# Mustache needs no runtime tag handlers or filters — its semantics
# compile entirely to core opcodes — so wiring a VM only means setting
# the partial compiler.

import std/[tables, sets]

import ../../bytecode
import ../../values
import ../../vm_types
import ../../vm
import lexer as mustache_lexer
import compiler as mustache_compiler

export bytecode, values, vm_types, vm
export mustache_lexer, mustache_compiler

proc compile_source*(source: string): CompileResult =
  ## Lex and compile Mustache source to Pitchfork bytecode.
  result = compile(lex_mustache(source))

proc mustache_partial_compiler(source: string): CompileResult {.nimcall.} =
  compile_source(source)

proc new_mustache_vm*(bytecode: seq[Instruction], strings: seq[string],
                      constants: seq[VMValue], root: VMValue,
                      context: ptr Table[string, VMValue],
                      partials: ptr Table[string, string] = nil): VM =
  ## Create a VM wired for Mustache: partials compile as Mustache, and the
  ## root data value sits at the bottom of the context stack (Mustache data
  ## may be a bare list or scalar, not just an object — `{{.}}` and `{{#.}}`
  ## address it directly). The context and partials are borrowed — they
  ## must outlive the VM (see new_vm).
  result = new_vm(bytecode, strings, constants, context, partials)
  result.partial_compiler = mustache_partial_compiler
  result.ctx_stack.add(root)

proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], root: VMValue, data: Table[string, VMValue],
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render compiled Mustache bytecode with the given data
  # The VM lives entirely inside this call, so borrowing the parameters
  # is safe.
  var vm = new_mustache_vm(bytecode, strings, constants, root,
                           unsafeAddr data, unsafeAddr partials)
  result = vm.execute()

proc render_tracked*(bytecode: seq[Instruction], strings: seq[string],
                     constants: seq[VMValue], root: VMValue, data: Table[string, VMValue],
                     partials: Table[string, string] = initTable[string, string]()):
                     tuple[output: string, accessed: HashSet[string]] =
  ## Render compiled Mustache bytecode and return both the output and the
  ## set of context variable paths accessed during execution.
  var vm = new_mustache_vm(bytecode, strings, constants, root,
                           unsafeAddr data, unsafeAddr partials)
  vm.track_access = true
  vm.path_stack = @[]
  vm.accessed_paths = initHashSet[string]()
  let output = vm.execute()
  result = (output, vm.accessed_paths)
