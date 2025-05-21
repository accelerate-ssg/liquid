import times
import golden_liquid/helpers

resetOutputFormatters()
addOutputFormatter(formatter)

let t0 = cpuTime()

include "golden_liquid/assign_tag"
# include "golden_liquid/capture_tag"
# include "golden_liquid/case_tag"
# include "golden_liquid/comment_tag"
# include "golden_liquid/cycle_tag"
# include "golden_liquid/decrement_tag"
# include "golden_liquid/echo_tag"
# include "golden_liquid/for_tag"
# include "golden_liquid/identifiers"
# include "golden_liquid/if_tag"

#include "golden_liquid/ifchanged_tag"
#include "golden_liquid/illegal"
#include "golden_liquid/include_tag"
#include "golden_liquid/increment_tag"
#include "golden_liquid/inline_comment_tag"
#include "golden_liquid/liquid_tag"
#include "golden_liquid/not_liquid"
#include "golden_liquid/output_statement"
#include "golden_liquid/range_objects"
#include "golden_liquid/raw_tag"
#include "golden_liquid/render_tag"
#include "golden_liquid/special"
#include "golden_liquid/tablerow_tag"
#include "golden_liquid/unless_tag"
#include "golden_liquid/unpac"
#include "golden_liquid/whitespace_control"

let t1 = cpuTime()
let duration = t1 - t0
echo "\nDuration: " & $duration & " seconds"

# Print failure summary
let failures = getFailures()
if failures.len > 0:
  echo "\nFailures:"
  var suiteName = ""
  for failure in failures:
    if failure.suiteName != suiteName:
      suiteName = failure.suiteName
      echo "\n  " & suiteName
    echo "    " & failure.testName
  echo ""
  quit(1)
else:
  echo "All tests passed!"
  quit(0)
