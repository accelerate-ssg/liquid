# Basic instructions

- Run the test suit with: `nim c -r test/golden_liquid.nim`
- Run a group from the suit with:
  `nim c -r test/golden_liquid.nim "the name of the group"`
- Run an individual test from the suit with:
  `nim c -r test/golden_liquid.nim "the name of the test"`
- Validate changes against the test suite often to avoid regressions.
- As soon as a task is completed, including the failing test count going done,
  commit the changes with a clear message.
- If you write tools to modify files use bash or nim, I do not have python or
  javascript setup available.
- Cleanup any temporary debug/test files created during the session before
  committing
- Commit before you run a script that modifies project files to avoid losing
  work.
- Use two sections in commit messages: Feature and Bug
- Use imperative mood words at the beginning of each item in the sections, like:
  Add, Remove, Change, Update etc
- Do not add author information to commit messages
- `rg` is available in path, use it to search for code.
- You are in /Users/jonas/projects/accodeing/accelerate/liquid
- `template` is a keyword in Nim, use `liquidTemplate` or `tmpl` as variables in
  test files.

# Codebase

## Implementation

- src/liquid/types.nim
- src/liquid/lexer.nim and src/liquid/lexer/\*.nim
- src/liquid/compiler.nim and src/liquid/compiler/\*nim
- src/liquid/vm.nim

## Tests

- Each of the main files for lexer, compileer and vm have a test suit that runs
  if you compile and run that file. These are baseline tests, add to them when a
  new feature is added and keep them passing when editing the implementation.
- Main test suit is test/golden_liquid.nim and the helpers in
  test/golden_liquid/helpers.nim

# Modifications

- A successful fix of a failing case results in no regressions.
- Don't forget to add base tests to the main files of each part when adding
  features.
