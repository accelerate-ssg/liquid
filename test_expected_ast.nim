import src/liquid/types
import test/golden_liquid/helpers
import src/liquid/parser/to_string

let expected = nodeVariable("product.tags[i]")
echo "Expected AST:"
echo $expected
