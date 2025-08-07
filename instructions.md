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

## Latest Progress Update (Major Breakthrough!)

**Recent Fixes Completed:**
- ✅ **Fixed tablerow tag test expectations**: Corrected 5/6 tablerow tests by fixing incorrect AST expectations that included body content  
- ✅ **Fixed echo tag bracket notation test**: Corrected test expectation to properly handle variable index evaluation in `product.tags[i]`
- ✅ **Fixed for tag comma-separated arguments**: Parser now correctly consumes comma after range expression and parses limit/offset arguments
- ✅ **Major Progress**: Failures reduced from 45 to 7 (97.8% pass rate: 308/315 tests passing)

**Key Discovery**: Most failures were **incorrect test expectations** rather than parser bugs, validating the instructions.md approach of "verify test correctness first"

**Remaining Failing Tests (7 remaining):**
1. **Range loop using identifier** (1 test) - Template/expectation mismatch needs investigation
2. **Tablerow "cols is a string"** (1 test) - Partial fix applied, minor debugging needed  
3. **Whitespace control with raw tags** (1 test) - Lexer section count mismatch
4. **Liquid tag nested functionality** (2 tests) - Multi-command parsing issues
5. **Render tag bound variables** (1 test) - Partial template system missing
6. **Inline comment tag** (1 test) - Lexer boundary issue with `#` comments

**Root Cause Analysis**: Remaining issues are primarily **lexer architecture** problems (section boundaries, tag content handling) rather than basic parser bugs.

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
- **Successes**: 308
- **Failures**: 7
- **Success rate**: 97.8%

**Excellent Progress**: Reduced failures from 45 → 12 → 7 through systematic test expectation corrections

## Major Failure Categories

**1. ~~Bracket Notation Issues~~ ✅ FIXED (15+ tests)**

- ~~Root cause: Parser not handling bracket notation correctly~~ ✅
- **Resolution**: Fixed parser to handle all bracket notation patterns correctly

**2. ~~Echo Tag Variable Index Tests~~ ✅ FIXED (1 test)**

- ~~Root cause: Test expectation was incorrect - should evaluate variable at runtime~~ ✅
- **Resolution**: Fixed test to expect proper variable node structure for bracket notation

**3. ~~For Tag Comma-Separated Arguments~~ ✅ FIXED (2 tests)**

- ~~Root cause: Parser not consuming comma after range expression~~ ✅
- **Resolution**: Added comma consumption before parsing arguments

**4. ~~Tablerow Tag Test Expectations~~ ✅ FIXED (5/6 tests)**

- ~~Root cause: Test expectations incorrectly included body content in tag AST~~ ✅
- **Resolution**: Corrected test structure to match parser architecture (separate sections for body content)
- **Key Insight**: Block tag body content is parsed as independent sections, not included in tag parameters

## Remaining Failure Categories (7 tests)

**1. Range Loop with Variable Bounds (1 test)**
- `{% for i in (0..product.end_range) %}` - Template/expectation mismatch
- Root cause: Possible test data inconsistency or range parsing issue

**2. Tablerow Parameter Edge Case (1 test)**  
- `cols:'2'` string parameter handling - Partial fix applied
- Root cause: Minor string token processing issue

**3. Raw Tag Whitespace Control (1 test)**
- `{%- raw -%}{{ hello }}{%- endraw -%}` - Section count mismatch
- Root cause: Lexer architecture for raw content handling

**4. Inline Comment Tag (1 test)**
- `{%- # {% echo 'hello world' %} -%}` - Lexer boundary parsing
- Root cause: Comment lexer should stop at first `%}` not consume all tokens

**5. Liquid Tag Multi-Command (2 tests)**
- Nested liquid with if, newline terminated tags
- Root cause: Multi-command parsing logic incomplete

**6. Render Tag Partial System (1 test)**
- `render with bound variable and alias`
- Root cause: Partial template system not implemented

# Priority Implementation Plan

## ~~High Priority~~ ✅ COMPLETED

1. ~~**Fix bracket notation parsing**~~ ✅ (15+ tests fixed)

   - Files: `src/liquid/parser/core.nim`
   - ~~Issue: Bracket notation expressions not parsing correctly~~
   - ~~Impact: Array/object access fundamentally broken~~
   - **Resolution**: Parser now correctly handles all bracket notation patterns including `[expr]`, `foo["bar"]`, nested brackets, and identifier-after-bracket cases

## High Priority (Final 7 failing tests)

**Focus**: All remaining issues are **lexer architecture** problems rather than basic parser bugs

1. **Fix inline comment tag lexer boundaries** (1 failing test)
   - Files: `src/liquid/parser/tags/comment_tag.nim`, lexer
   - Issue: Comment lexer consuming all tokens instead of stopping at tag boundary
   - Impact: Inline comments `{%- # ... %}` not parsing correctly
   - **Priority**: HIGH - Clear fix needed in token consumption logic

2. **Fix tablerow 'cols is a string' edge case** (1 failing test)
   - Files: Test expectation debugging
   - Issue: String parameter token processing  
   - Impact: Minor parameter handling issue
   - **Priority**: HIGH - Small fix, partial solution already applied

3. **Fix range loop template/expectation mismatch** (1 failing test)
   - Files: Test data investigation needed
   - Issue: Template `(0..product.end_range)` vs actual parsing
   - Impact: Dynamic range evaluation
   - **Priority**: MEDIUM - Requires debugging test runner

4. **Fix raw tag whitespace lexer architecture** (1 failing test)
   - Files: `src/liquid/lexer/sections.nim`, raw tag handling
   - Issue: Section count mismatch in raw content lexing
   - Impact: Raw tag whitespace control broken  
   - **Priority**: MEDIUM - Complex lexer changes needed

5. **Fix liquid tag multi-command parsing** (2 failing tests)
   - Files: `src/liquid/parser/tags/liquid.nim`
   - Issue: Multi-command parsing logic incomplete
   - Impact: Advanced liquid tag functionality
   - **Priority**: MEDIUM - Feature enhancement

6. **Implement render tag partial system** (1 failing test)
   - Files: `src/liquid/parser/tags/render.nim`, new partial system
   - Issue: Partial template system missing entirely
   - Impact: Template composition functionality  
   - **Priority**: LOW - Major new feature, not core parsing

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

## ✅ ACHIEVED - Major Success!

- ✅ **Reduced failures from 45 to 7** (308/315 tests passing - **97.8% success rate**)
- ✅ **Fixed all bracket notation issues** (15+ tests)
- ✅ **Fixed tablerow tag expectations** (5/6 tests) - **Major breakthrough**
- ✅ **Fixed echo tag and for tag parsing**
- ✅ **Validated instructions.md approach**: "Verify test correctness first" - most issues were incorrect expectations!

## Short-term (Next Sprint)

- **Current Goal: Fix final 7 failing tests to reach 98%+ pass rate**
- **Priority 1**: Fix inline comment lexer boundaries (clear solution identified)  
- **Priority 2**: Fix tablerow 'cols is a string' edge case (partial fix applied)
- **Target**: 312/315 tests passing (99% success rate)

## Medium-term (1 month)

- **Achieve 99%+ test pass rate** (Target: 313-314/315 tests)
- **Focus on lexer architecture improvements** for remaining edge cases
- **Add render tag partial template system** (major feature)

## Long-term (2-3 months)

- Full Liquid template compatibility
- Performance optimization
- Comprehensive error handling
