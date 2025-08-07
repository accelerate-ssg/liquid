import times, strutils, strformat, sequtils
import src/liquid/lexer

# Test data with varying complexity
const testTemplates = [
  # Simple text
  "Hello World",
  
  # Simple output
  "Hello {{ name }}",
  
  # Complex template with multiple sections
  """
  <html>
    <head><title>{{ page.title }}</title></head>
    <body>
      {% for item in items %}
        <div class="{{ item.class }}">
          {{ item.name | upcase | truncate: 50 }}
          {% if item.description %}
            <p>{{ item.description }}</p>
          {% endif %}
        </div>
      {% endfor %}
    </body>
  </html>
  """,
  
  # Raw content test
  """
  {% raw %}
    This is raw content with {{ variables }} and {% tags %}
    that should not be parsed.
  {% endraw %}
  """,
  
  # Large template with repetitive content
  (0..100).mapIt("{{ item" & $it & " }} ").join(""),
  
  # Complex nested structure
  """
  {% liquid
    assign products = collections.all.products
    for product in products
      if product.available
        assign price = product.price | money
        echo product.title
        echo price
      endif
    endfor
  %}
  """
]

proc benchmarkLexer() =
  echo "Lexer Performance Benchmark"
  echo "=".repeat(50)
  
  for i, tmpl in testTemplates:
    echo &"Test {i+1}: {tmpl.len} characters"
    
    let iterations = if tmpl.len < 100: 10000 
                    elif tmpl.len < 1000: 1000 
                    else: 100
    
    let startTime = cpuTime()
    for _ in 1..iterations:
      discard lex(tmpl)
    let endTime = cpuTime()
    
    let totalTime = endTime - startTime
    let avgTime = totalTime / iterations.float * 1000.0  # Convert to milliseconds
    let charsPerSec = (tmpl.len.float * iterations.float) / totalTime
    
    echo &"  Iterations: {iterations}"
    echo &"  Total time: {totalTime:.3f}s"
    echo &"  Avg per lex: {avgTime:.3f}ms"
    echo &"  Chars/sec: {charsPerSec:.0f}"
    echo ""

when isMainModule:
  benchmarkLexer()