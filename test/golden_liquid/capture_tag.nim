suite "capture tag":
  testCase(
    "assign to a variable from a captured variable",
    """{% capture some %}hello{% endcapture %}{% assign other = some %}{{ some }}-{{ other }}""",
    output = "hello-hello"
  )

  testCase(
    "capture into a variable with a hyphen",
    """{% capture this-thing %}Hello, {{ customer.first_name }}.{% endcapture %}{{ this-thing }}""",
    context = %*{"customer": {"first_name": "Holly"}},
    output = "Hello, Holly."
  )

  testCase(
    "capture template literal and global variable",
    """{% capture greeting %}Hello, {{ customer.first_name }}.{% endcapture %}{{ greeting }}""",
    context = %*{"customer": {"first_name": "Holly"}},
    output = "Hello, Holly."
  )
