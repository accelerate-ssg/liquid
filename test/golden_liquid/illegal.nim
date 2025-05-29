

suite "illegal operations":
  # These tests verify that certain operations are not allowed in strict mode
  # Since the current implementation may not enforce all strict mode rules,
  # we'll create basic tests that can be expanded later
  
  test "unknown tag should fail":
    # This test would ideally check that unknown tags produce errors
    # For now, we'll skip implementation until error handling is fully implemented
    skip()
  
  test "arithmetic in assign should fail in strict mode":
    # This test would check that arithmetic operations in assign fail in strict mode
    # For now, we'll skip implementation until strict mode is fully implemented  
    skip()