///|
test "name" {
  let m : &@ms.PromptModule = GitStatusModule::new()
  assert_eq(m.name(), "git_status")
}

///|
test "build_status_string: all types" {
  let result = build_status_string([
    (1, "⇡"),
    (0, "⇣"),
    (2, "+"),
    (1, "!"),
    (3, "?"),
  ])
  assert_eq(result, "⇡+2!?3")
}

///|
test "build_status_string: all zero" {
  let result = build_status_string([
    (0, "⇡"),
    (0, "⇣"),
    (0, "+"),
    (0, "!"),
    (0, "?"),
  ])
  assert_eq(result, "")
}

///|
test "build_status_string: count=1 symbol only" {
  assert_eq(build_status_string([(1, "+")]), "+")
}

///|
test "build_status_string: count>1 symbol+number" {
  assert_eq(build_status_string([(5, "+")]), "+5")
}
