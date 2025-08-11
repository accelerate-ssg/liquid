

suite "comment tag":
  testCase(
    "don't render comments",
    "{% comment %}foo{% endcomment %}",
    output = ""
  )

  testCase(
    "don't render comments with tags",
    "{% comment %}{% if true %}{{ title }}{% endif %}{% endcomment %}",
    output = ""
  )

  testCase(
    "respect whitespace control in comments",
    "\n{%- comment %}foo{% endcomment -%}\t \r",
    output = ""
  )
