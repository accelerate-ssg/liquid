proc createTagSection(kind: NodeKind): Section =
  result = Section(sectionType: Tag)
  result.ast = Node(kind: kind)

suite "Section nesting":
  test "Valid simple tag nesting":
    let testSections = @[
      createTagSection(nkIf),
      createTagSection(nkEndIf)
    ]
    check validateTagNesting(testSections) == true

  test "Valid complex tag nesting":
    let testSections = @[
      createTagSection(nkIf),
        createTagSection(nkFor),
        createTagSection(nkEndFor),
      createTagSection(nkElsIf),
        createTagSection(nkCapture),
        createTagSection(nkEndCapture),
      createTagSection(nkElse),
        createTagSection(nkCase),
          createTagSection(nkWhen),
          createTagSection(nkWhen),
        createTagSection(nkEndCase),
      createTagSection(nkEndIf)
    ]
    check validateTagNesting(testSections) == true

  test "Valid nested if statements":
    let testSections = @[
      createTagSection(nkIf),
        createTagSection(nkIf),
          createTagSection(nkIf),
          createTagSection(nkEndIf),
        createTagSection(nkElse),
          createTagSection(nkUnless),
          createTagSection(nkEndUnless),
        createTagSection(nkEndIf),
      createTagSection(nkEndIf)
    ]
    check validateTagNesting(testSections) == true

  test "Valid mix of if and unless":
    let testSections = @[
      createTagSection(nkUnless),
        createTagSection(nkIf),
        createTagSection(nkEndIf),
      createTagSection(nkElsUnless),
        createTagSection(nkIf),
          createTagSection(nkElse),
        createTagSection(nkEndIf),
      createTagSection(nkElse),
      createTagSection(nkEndUnless)
    ]
    check validateTagNesting(testSections) == true

  test "Invalid: Mismatched closing tag":
    let testSections = @[
      createTagSection(nkIf),
      createTagSection(nkEndUnless)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: Missing closing tag":
    let testSections = @[
      createTagSection(nkIf),
        createTagSection(nkFor),
      createTagSection(nkEndIf)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: Extra closing tag":
    let testSections = @[
      createTagSection(nkIf),
      createTagSection(nkEndIf),
      createTagSection(nkEndIf)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: Incorrectly nested tags":
    let testSections = @[
      createTagSection(nkIf),
        createTagSection(nkFor),
      createTagSection(nkEndIf),
      createTagSection(nkEndFor)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: Continuation tag without opening":
    let testSections = @[
      createTagSection(nkElse)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: Wrong continuation tag":
    let testSections = @[
      createTagSection(nkUnless),
      createTagSection(nkElsIf),
      createTagSection(nkEndUnless)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Valid: Empty sequence":
    let testSections: seq[Section] = @[]
    check validateTagNesting(testSections) == true

  test "Valid: Sequence with non-tag sections":
    let testSections = @[
      Section(sectionType: Text),
      createTagSection(nkIf),
      Section(sectionType: Output),
      createTagSection(nkEndIf),
      Section(sectionType: Text)
    ]
    check validateTagNesting(testSections) == true

  test "Valid: Complex case statement":
    let testSections = @[
      createTagSection(nkCase),
        createTagSection(nkWhen),
        createTagSection(nkWhen),
        createTagSection(nkWhen),
      createTagSection(nkEndCase)
    ]
    check validateTagNesting(testSections) == true

  test "Invalid: Case without when":
    let testSections = @[
      createTagSection(nkCase),
      createTagSection(nkEndCase)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Invalid: When without case":
    let testSections = @[
      createTagSection(nkWhen)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Valid: Case with when":
    let testSections = @[
      createTagSection(nkCase),
      createTagSection(nkWhen),
      createTagSection(nkEndCase)
    ]
    check validateTagNesting(testSections) == true

  test "Invalid: Unclosed case without when":
    let testSections = @[
      createTagSection(nkCase)
    ]
    expect ValueError:
      discard validateTagNesting(testSections)

  test "Valid: Multiple case statements":
    let testSections = @[
      createTagSection(nkCase),
      createTagSection(nkWhen),
      createTagSection(nkEndCase),
      createTagSection(nkCase),
      createTagSection(nkWhen),
      createTagSection(nkWhen),
      createTagSection(nkEndCase)
    ]
    check validateTagNesting(testSections) == true
