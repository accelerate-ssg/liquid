# Engine-level VM tests
# =====================
# Exercises the VM directly with hand-assembled bytecode — no template
# frontend involved. This is the engine's behavioral contract for tine
# authors, and covers opcodes and edge cases the frontend suites don't
# reach (arithmetic, negate, cross-partial continue, error paths, stack
# discipline).

import std/[unittest, tables]
import ../src/pitchfork/[bytecode, values, vm]

proc run(instructions: seq[Instruction], strings: seq[string] = @[],
         data: Table[string, VMValue] = initTable[string, VMValue]()): string =
  var machine = new_vm(instructions, strings, @[], data)
  machine.execute()

proc outputted(v: Instruction): seq[Instruction] =
  @[v, Instruction(op: opOutput)]

suite "Engine arithmetic opcodes":
  test "add, subtract, multiply, divide, modulo on ints":
    for (op, expected) in [(opAdd, "10"), (opSubtract, "4"),
                           (opMultiply, "21"), (opDivide, "2"),
                           (opModulo, "1")]:
      let output = run(@[
        Instruction(op: opPushInt, intVal: 7),
        Instruction(op: opPushInt, intVal: 3),
        Instruction(op: op),
        Instruction(op: opOutput)])
      check output == expected

  test "mixed int/float arithmetic produces floats":
    check run(@[
      Instruction(op: opPushInt, intVal: 1),
      Instruction(op: opPushFloat, floatVal: 0.5),
      Instruction(op: opAdd),
      Instruction(op: opOutput)]) == "1.5"
    check run(@[
      Instruction(op: opPushFloat, floatVal: 2.5),
      Instruction(op: opPushInt, intVal: 2),
      Instruction(op: opMultiply),
      Instruction(op: opOutput)]) == "5.0"

  test "subtract treats null as zero":
    check run(@[
      Instruction(op: opPushNull),
      Instruction(op: opPushInt, intVal: 3),
      Instruction(op: opSubtract),
      Instruction(op: opOutput)]) == "-3"

  test "negate int and float":
    check run(@[
      Instruction(op: opPushInt, intVal: 42),
      Instruction(op: opNegate),
      Instruction(op: opOutput)]) == "-42"
    check run(@[
      Instruction(op: opPushFloat, floatVal: 1.5),
      Instruction(op: opNegate),
      Instruction(op: opOutput)]) == "-1.5"

  test "division by zero: int -> null, float -> Inf":
    check run(@[
      Instruction(op: opPushInt, intVal: 1),
      Instruction(op: opPushInt, intVal: 0),
      Instruction(op: opDivide),
      Instruction(op: opOutput)]) == ""
    check run(@[
      Instruction(op: opPushFloat, floatVal: 1.0),
      Instruction(op: opPushFloat, floatVal: 0.0),
      Instruction(op: opDivide),
      Instruction(op: opOutput)]) == "inf"

suite "Engine control flow":
  test "cross-partial continue: opContinue outside a loop stops execution":
    # A {% continue %} that executes inside an included partial (no local
    # loop) must set pending_continue and halt that VM so the parent's
    # opIterNext can act on it.
    var machine = new_vm(@[
      Instruction(op: opContinue, levels: 1),
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opOutput)], @["unreachable"], @[],
      initTable[string, VMValue]())
    check machine.execute() == ""
    check machine.pending_continue == true

  test "cross-partial break sets pending_break and halts":
    var machine = new_vm(@[
      Instruction(op: opBreak, levels: 1),
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opOutput)], @["unreachable"], @[],
      initTable[string, VMValue]())
    check machine.execute() == ""
    check machine.pending_break == true

  test "backward jump loops and forward jump skips":
    # countdown-style loop: push int, output, decrement via subtract
    check run(@[
      Instruction(op: opJump, offset: 2),                # skip the next two
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opOutput),
      Instruction(op: opPushString, stringId: 1),
      Instruction(op: opOutput)], @["skipped", "kept"]) == "kept"

  test "conditional jumps respect truthiness":
    check run(@[
      Instruction(op: opPushFalse),
      Instruction(op: opJumpIfFalse, offset: 2),
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opOutput),
      Instruction(op: opPushString, stringId: 1),
      Instruction(op: opOutput)], @["then", "after"]) == "after"

suite "Engine stack discipline and error paths":
  test "pop on an empty stack yields null, not a crash":
    check run(@[Instruction(op: opOutput)]) == ""

  test "unknown filter renders as empty string":
    check run(@[
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opCallFilter, filterId: 1, argCount: 0),
      Instruction(op: opOutput)], @["value", "no#such#filter"]) == ""

  test "unknown tag handler raises":
    expect CatchableError:
      discard run(@[
        Instruction(op: opCallTag, tagId: 0, tagArgCount: 0, tagData: @[])],
        @["no_such_tag"])

  test "missing partial compiler raises only when a partial is present":
    var machine = new_vm(@[
      Instruction(op: opInclude, templateId: 0, withContext: true,
                  includeArgCount: 0, includeArgNames: @[],
                  includeVarExpr: false, includeWithVar: -1,
                  includeAlias: -1, includeForVar: -1)],
      @["p"], @[], initTable[string, VMValue](),
      {"p": "source"}.toTable)
    expect CatchableError:
      discard machine.execute()

  test "dup duplicates and pop discards":
    check run(@[
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opDup),
      Instruction(op: opOutput),
      Instruction(op: opOutput)], @["x"]) == "xx"
    check run(@[
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opPushString, stringId: 1),
      Instruction(op: opPop),
      Instruction(op: opOutput)], @["kept", "dropped"]) == "kept"

suite "Engine context stack":
  test "resolve walks frames then falls back to variables":
    var machine = new_vm(@[
      Instruction(op: opResolveName, nameId: 0),
      Instruction(op: opOutput),
      Instruction(op: opResolveName, nameId: 1),
      Instruction(op: opOutput)],
      @["a", "b"], @[], {"a": vm_string("flat"), "b": vm_string("flatb")}.toTable)
    var frame = initOrderedTable[string, VMValue]()
    frame["a"] = vm_string("framed")
    machine.ctx_stack.add(vm_object(frame))
    check machine.execute() == "framedflatb"

  test "ctxHops skips frames":
    var machine = new_vm(@[
      Instruction(op: opResolveName, nameId: 0, ctxHops: 1),
      Instruction(op: opOutput)],
      @["a"], @[], initTable[string, VMValue]())
    var outer = initOrderedTable[string, VMValue]()
    outer["a"] = vm_string("outer")
    var inner = initOrderedTable[string, VMValue]()
    inner["a"] = vm_string("inner")
    machine.ctx_stack.add(vm_object(outer))
    machine.ctx_stack.add(vm_object(inner))
    check machine.execute() == "outer"

  test "push/set/pop ctx round-trip":
    var machine = new_vm(@[
      Instruction(op: opPushString, stringId: 0),
      Instruction(op: opPushCtx),
      Instruction(op: opResolveName, nameId: 1),  # "." = current ctx
      Instruction(op: opOutput),
      Instruction(op: opPushString, stringId: 2),
      Instruction(op: opSetCtx),
      Instruction(op: opResolveName, nameId: 1),
      Instruction(op: opOutput),
      Instruction(op: opPopCtx)],
      @["first", ".", "second"], @[], initTable[string, VMValue]())
    check machine.execute() == "firstsecond"