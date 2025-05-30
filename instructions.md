# Basic instructions

Test suit: nim c -r test/golden_liquid.nim
Validate changes against the test suite often to avoid regressions.
As soon as a task is completed, including the failing test count going done,
commit the changes with a clear message.
If you write tools to modify files use bash or nim, I do not have python or
javascript setup available. Commit before you run a script that modifies files
to avoid losing work.
rg is available in path, use it to search for code.

# Fixing defecits

When the test does not pass we need to verify the following:

1. Test correctness. The unmodified test data is available in
   `test/golden_liquid/golden_liquid.json`, make sure the test is correct first.
2. If the test data is correct and the test if failing because of a bug in the
   lexer tokens or AST expected it might simply be that the test is incorrect.
3. If the test is correct and the lexer and AST looks correct, then it might
   be that the renderer is not implemented correctly.

# Current State Overview

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
- **Successes**: 270
- **Failures**: 45
- **Success rate**: 85.7%

## Major Failure Categories

**1. ~~Bracket Notation Issues~~ ✅ FIXED (15+ tests)**

- ~~`{{ [something] }}` - bracket notation without identifier~~ ✅
- ~~`{{ foo["bar"] }}` - quoted bracket access~~ ✅
- ~~`{{ foo["bar baz"] }}` - bracket access with spaces~~ ✅
- ~~Root cause: Parser not handling bracket notation correctly~~ ✅
- **Resolution**: Fixed parser to handle all bracket notation patterns correctly

**2. Range Object Evaluation (6+ tests)**

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

## High Priority (Next to implement)

2. **Implement range object rendering** (6+ failing tests)

   - Files: `src/liquid/renderer.nim`
   - Issue: Range evaluation not implemented
   - Impact: Range expressions don't work

3. **Fix output statement rendering** (8+ failing tests)

   - Files: `src/liquid/renderer.nim`
   - Issue: Complex expression evaluation edge cases
   - Impact: Basic template features broken

4. **Implement 'unless' tag else/elsif branches** (6+ failing tests)

   - Files: `src/liquid/parser/tags/unless.nim`
   - Issue: Parser expects branches but they're not implemented
   - Impact: Conditional logic incomplete

5. **Implement 'raw' tag content preservation** (5+ failing tests)
   - Files: `src/liquid/parser/tags/raw.nim`, renderer
   - Issue: Raw content not preserved
   - Impact: Literal content rendering broken

## Medium Priority (Important Features)

6. **Implement 'tablerow' tag HTML generation**

   - Files: `src/liquid/parser/tags/tablerow.nim`
   - Issue: No HTML table generation
   - Impact: Table rendering not available

7. **Implement 'capture' tag variable assignment**

   - Files: `src/liquid/parser/tags/capture.nim`
   - Issue: Parsing exists but no rendering logic
   - Impact: Content capture not working

8. **Implement 'case/when' tag conditional logic**

   - Files: `src/liquid/parser/tags/case_tag.nim`
   - Issue: No rendering implementation
   - Impact: Switch-case conditionals missing

9. **Implement 'cycle' tag state management**

   - Files: `src/liquid/parser/tags/cycle.nim`
   - Issue: No state management
   - Impact: Value cycling not available

10. **Implement 'liquid' tag multi-command execution**

    - Files: `src/liquid/parser/tags/liquid.nim`
    - Issue: Parsing works but rendering doesn't execute
    - Impact: Multi-command blocks broken

11. **Implement 'render' tag partial template system**

    - Files: `src/liquid/parser/tags/render.nim`
    - Issue: No partial template support
    - Impact: Template composition not available

12. **Implement special variable properties**
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

## Short-term (1-2 weeks)

- ~~Reduce test failures from 54 to under 20~~ ✅ (Already at 45)
- ~~Fix all bracket notation issues~~ ✅ (Completed)
- Implement range object rendering (Next priority)

## Medium-term (1 month)

- Achieve 95%+ test pass rate
- Implement all missing tag rendering
- Add partial template system

## Long-term (2-3 months)

- Full Liquid template compatibility
- Performance optimization
- Comprehensive error handling
