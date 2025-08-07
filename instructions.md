# Basic instructions

Test suit: nim c -r test/golden_liquid.nim
Validate changes against the test suite often to avoid regressions.
As soon as a task is completed, including the failing test count going done,
commit the changes with a clear message.
If you write tools to modify files use bash or nim, I do not have python or
javascript setup available. Commit before you run a script that modifies files
to avoid losing work.
`rg` is available in path, use it to search for code.
Your are in /Users/jonas/projects/accodeing/accelerate/liquid

# Fixing defecits

When the test does not pass we need to verify the following:

1. Test correctness. The unmodified test data is available in
   `test/golden_liquid/golden_liquid.json`, make sure the test is correct first.
2. If the test data is correct and the test if failing because of a bug in the
   lexer tokens or AST expected it might simply be that the test is incorrect.
3. If the test is correct and the lexer and AST looks correct, then it might
   be that the renderer is not implemented correctly.

# Current State Overview

## Latest Progress Update

**Recent Fixes Completed:**
- ✅ **Fixed echo tag bracket notation test**: Corrected test expectation to properly handle variable index evaluation in `product.tags[i]`
- ✅ **Fixed for tag comma-separated arguments**: Parser now correctly consumes comma after range expression and parses limit/offset arguments
- ✅ **Progress**: Failures reduced from 14 to 12 (96.2% pass rate: 303/315 tests passing)

**Current Failing Tests (12 remaining):**
1. **Range loop using identifier** (1 test) - Loop over range with variable bounds
2. **Tablerow tag functionality** (6 tests) - HTML table generation with various options
3. **Whitespace control with raw tags** (1 test) - Raw tag content preservation
4. **Liquid tag nested functionality** (2 tests) - Multi-command execution
5. **Render tag bound variables** (1 test) - Partial template rendering
6. **Inline comment tag** (1 test) - Comment parsing issue

## What's Already Implemented

**Core Renderer Architecture:**

- Main renderer in `src/liquid/renderer.nim` (467 lines)
- Context type defined as `JsonNode` alias in `shared.nim`
- Two main rendering functions: `renderSections()` and `renderTemplate()`

**Evaluation Engine:**

- Comprehensive `evaluate()` function that handles all AST node types
- Variable resolution with dot notation and array indexing
- Operator evaluation (arithmetic, comparison, logical)
- Filter application integration
- Range evaluation
- Array and object access

**Section Rendering:**

- Text sections with whitespace control
- Output sections (variable interpolation)
- Tag sections with conditional logic

**Tag Support:**

- **if/unless**: Full conditional rendering with else/elsif branches
- **for**: Loop rendering with proper scoping
- **assign**: Variable assignment
- Basic tag structure for other tags

**Filter Integration:**

- Filter macro system in `shared.nim` for type-safe filter creation
- Dynamic filter lookup table
- Support for chained filters

## What's Missing or Incomplete

**Missing Tag Implementations:**

- **capture**: Tag parsing exists but rendering is incomplete
- **case/when**: No rendering logic
- **cycle**: No rendering logic
- **increment/decrement**: Basic evaluation only
- **tablerow**: No rendering logic
- **render**: No partial template support
- **liquid**: Multi-command tag not implemented
- **raw**: No content preservation
- **comment**: No block handling
- **ifchanged**: No state tracking

**Missing Core Features:**

- **Partial template system**: No support for `{% render %}` tag
- **Template inheritance**: No include/extends functionality
- **Advanced loop variables**: `forloop.first`, `forloop.last`, etc.
- **Nested template contexts**: Variable scoping for includes
- **Error handling**: Limited error reporting and recovery

**Missing Advanced Rendering:**

- **Custom tag registration**: No plugin system
- **Template caching**: No performance optimization
- **Async rendering**: Synchronous only
- **Stream rendering**: Loads everything into memory

## Architecture Analysis

**Current Flow:**

1. `lex()` → tokenize template into sections
2. `parse()` → build AST nodes from tokens
3. `renderSections()` → evaluate and render to string

**AST Structure:**

- Well-defined `Node` types covering all liquid constructs
- Proper separation of parsing and rendering concerns
- JsonNode-based context for variable storage

**Evaluation System:**

- Recursive evaluation of nested expressions
- Proper type coercion and null handling
- Support for liquid's truthiness rules

# Test Analysis

## Current Test Status

- **Total tests**: 315
- **Successes**: 303
- **Failures**: 12
- **Success rate**: 96.2%

## Major Failure Categories

**1. ~~Bracket Notation Issues~~ ✅ FIXED (15+ tests)**

- ~~`{{ [something] }}` - bracket notation without identifier~~ ✅
- ~~`{{ foo["bar"] }}` - quoted bracket access~~ ✅
- ~~`{{ foo["bar baz"] }}` - bracket access with spaces~~ ✅
- ~~Root cause: Parser not handling bracket notation correctly~~ ✅
- **Resolution**: Fixed parser to handle all bracket notation patterns correctly

**2. ~~Echo Tag Variable Index Tests~~ ✅ FIXED (1 test)**

- ~~`product.tags[i]` where `i` is a variable~~ ✅
- ~~Root cause: Test expectation was incorrect - should evaluate variable at runtime~~ ✅
- **Resolution**: Fixed test to expect proper variable node structure for bracket notation

**3. ~~For Tag Comma-Separated Arguments~~ ✅ FIXED (2 tests)**

- ~~`{% for i in (1..6), limit: 4, offset: 2 %}`~~ ✅
- ~~Root cause: Parser not consuming comma after range expression~~ ✅
- **Resolution**: Added comma consumption before parsing arguments

**4. Range Object Evaluation (remaining tests)**

- `(1..5)` - basic range rendering
- `(foo..5)` - range with variables
- `(1.4..5)` - range with floats
- Root cause: Range evaluation not implemented in renderer

**3. Output Statement Rendering (8+ tests)**

- Complex filter chains
- Negative number literals
- Nested expressions with operators
- Root cause: Expression evaluation edge cases

**4. Missing Tag Branch Support (6+ tests)**

- `unless` with `else`/`elsif` branches
- Parser expects these but renderer doesn't handle them
- Root cause: Incomplete tag implementations

**5. Raw Tag Content (5+ tests)**

- Raw content not preserved correctly
- Whitespace control interaction issues
- Root cause: Raw tag implementation missing

# Priority Implementation Plan

## ~~High Priority~~ ✅ COMPLETED

1. ~~**Fix bracket notation parsing**~~ ✅ (15+ tests fixed)

   - Files: `src/liquid/parser/core.nim`
   - ~~Issue: Bracket notation expressions not parsing correctly~~
   - ~~Impact: Array/object access fundamentally broken~~
   - **Resolution**: Parser now correctly handles all bracket notation patterns including `[expr]`, `foo["bar"]`, nested brackets, and identifier-after-bracket cases

## High Priority (Current 12 failing tests)

1. **Fix tablerow tag HTML generation** (6 failing tests)
   - Files: `src/liquid/parser/tags/tablerow.nim`, renderer
   - Issue: No HTML table generation implementation
   - Impact: Table rendering completely broken
   - Tests: `one row`, `two columns`, `one row with limit`, `one row with offset`, `two column range`, `cols is a string`

2. **Fix liquid tag nested functionality** (2 failing tests)
   - Files: `src/liquid/parser/tags/liquid.nim`, renderer
   - Issue: Multi-command execution not working properly
   - Impact: Multi-command blocks broken
   - Tests: `nested liquid with if`, `newline terminated tags`

3. **Fix range loop with identifier** (1 failing test)
   - Files: `src/liquid/renderer.nim`
   - Issue: Range evaluation with variable bounds not working
   - Impact: Dynamic range loops broken
   - Tests: `range loop using identifier`

4. **Fix whitespace control with raw tags** (1 failing test)
   - Files: `src/liquid/parser/tags/raw.nim`, renderer
   - Issue: Raw content not preserving whitespace correctly
   - Impact: Raw content rendering broken
   - Tests: `white space control with raw tags`

5. **Fix render tag bound variables** (1 failing test)
   - Files: `src/liquid/parser/tags/render.nim`, renderer
   - Issue: Partial template rendering with variable binding
   - Impact: Advanced template composition broken
   - Tests: `render with bound variable and alias`

6. **Fix inline comment tag** (1 failing test)
   - Files: `src/liquid/parser/tags/comment.nim`, renderer  
   - Issue: Comment tag parsing issue
   - Impact: Comment functionality broken
   - Tests: `can't comment tags`

## Medium Priority (Future Enhancements)

1. **Implement 'capture' tag variable assignment**
   - Files: `src/liquid/parser/tags/capture.nim`
   - Issue: Parsing exists but no rendering logic
   - Impact: Content capture not working

2. **Implement 'case/when' tag conditional logic**
   - Files: `src/liquid/parser/tags/case_tag.nim`
   - Issue: No rendering implementation
   - Impact: Switch-case conditionals missing

3. **Implement 'cycle' tag state management**
   - Files: `src/liquid/parser/tags/cycle.nim`
   - Issue: No state management
   - Impact: Value cycling not available

4. **Implement special variable properties**
   - Files: `src/liquid/renderer.nim`
   - Issue: `.first`, `.last`, `.size` for objects not implemented
   - Impact: Object property access limited

## Low Priority (Nice to Have)

13. **Implement advanced forloop variables**

    - Files: `src/liquid/renderer.nim`
    - Issue: `forloop.first`, `forloop.last`, etc. missing
    - Impact: Advanced loop features unavailable

14. **Implement 'ifchanged' tag**

    - Files: `src/liquid/parser/tags/ifchanged.nim`
    - Issue: No state tracking implementation
    - Impact: Change detection not available

15. **Add error handling and recovery**

    - Files: Throughout renderer
    - Issue: Limited error reporting
    - Impact: Poor debugging experience

16. **Add template caching system**

    - Files: New caching module
    - Issue: No performance optimization
    - Impact: Slow repeated renders

17. **Implement template inheritance**
    - Files: New include/extends system
    - Issue: No template composition system
    - Impact: Advanced templating not available

# Key Architecture Decisions Needed

## 1. Partial Template System Design

- How to resolve template paths
- Variable scoping for includes
- Template caching strategy
- Error handling for missing partials

## 2. State Management for Stateful Tags

- Where to store cycle state
- How to handle ifchanged state
- Session vs. template-local state

## 3. Error Handling Strategy

- Graceful degradation vs. strict failures
- Error context preservation
- User-friendly error messages

## 4. Performance Optimization

- Template compilation vs. interpretation
- Caching strategies
- Memory usage optimization

# Files Requiring Major Changes

## Parser Files (Medium Priority)

- `src/liquid/parser/core.nim` - Fix bracket notation
- `src/liquid/parser/tags/unless.nim` - Add branch support
- `src/liquid/parser/tags/raw.nim` - Fix content preservation

## Renderer Files (High Priority)

- `src/liquid/renderer.nim` - Core rendering improvements
- `src/liquid/types.nim` - May need new node types

## New Files Needed

- Template caching system
- Partial template resolver
- Advanced error handling module

# Testing Strategy

## Immediate Focus

1. Fix the 54 failing tests systematically
2. Start with high-impact, low-complexity fixes
3. Ensure no regressions with existing passing tests

## Long-term Testing

1. Add performance benchmarks
2. Add stress tests for complex templates
3. Add edge case tests for error conditions

# Success Metrics

## Short-term (Next Sprint)

- ✅ **Reduced failures from 45 to 12** (303/315 tests passing - 96.2% success rate)
- ✅ **Fixed all bracket notation issues** 
- ✅ **Fixed echo tag and for tag parsing**
- **Next Goal: Fix tablerow tag (6 tests) - biggest impact**
- **Target: Get below 6 failing tests (98%+ pass rate)**

## Medium-term (1 month)

- Achieve 95%+ test pass rate
- Implement all missing tag rendering
- Add partial template system

## Long-term (2-3 months)

- Full Liquid template compatibility
- Performance optimization
- Comprehensive error handling
