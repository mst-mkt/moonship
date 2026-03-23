///|
test "visible_width: plain text" {
  assert_eq(visible_width("hello"), 5)
}

///|
test "visible_width: with ANSI escape" {
  assert_eq(visible_width("\u001b[1;31mhello\u001b[0m"), 5)
}

///|
test "visible_width: empty string" {
  assert_eq(visible_width(""), 0)
}

///|
test "visible_width: only ANSI escapes" {
  assert_eq(visible_width("\u001b[0m\u001b[1m"), 0)
}

///|
test "repeat_to_width: single char" {
  assert_eq(repeat_to_width(".", 5), ".....")
}

///|
test "repeat_to_width: multi char cyclic" {
  assert_eq(repeat_to_width("-:", 6), "-:-:-:")
}

///|
test "repeat_to_width: zero width" {
  assert_eq(repeat_to_width(".", 0), "")
}

///|
test "repeat_to_width: empty symbol" {
  assert_eq(repeat_to_width("", 5), "")
}

///|
test "repeat_to_width: width less than symbol length" {
  assert_eq(repeat_to_width("abc", 2), "ab")
}

///|
test "render_with_fill: no fill segments" {
  let output = ModuleOutput::new([
    Segment::new("hello", style=@terminal.Style::default()),
  ])
  let result = output.render_with_fill(80)
  assert_eq(result, "hello")
}

///|
test "render_with_fill: single fill expands to remaining width" {
  let output = ModuleOutput::new([
    Segment::new("AB"),
    Segment::fill(".", @terminal.Style::default()),
    Segment::new("CD"),
  ])
  let result = output.render_with_fill(10)
  assert_true(result.contains("......"))
  assert_true(result.contains("AB"))
  assert_true(result.contains("CD"))
}

///|
test "render_with_fill: zero remaining width" {
  let output = ModuleOutput::new([
    Segment::new("ABCDEFGHIJ"),
    Segment::fill(".", @terminal.Style::default()),
  ])
  let result = output.render_with_fill(5)
  assert_true(result.contains("ABCDEFGHIJ"))
}

///|
test "render_with_fill: multiple fills share remaining width" {
  let output = ModuleOutput::new([
    Segment::new("A"),
    Segment::fill(".", @terminal.Style::default()),
    Segment::new("B"),
    Segment::fill(".", @terminal.Style::default()),
    Segment::new("C"),
  ])
  let result = output.render_with_fill(13)

  // 3 chars used (A, B, C), 10 remaining, 2 fills -> 5 each
  assert_true(result.contains("A"))
  assert_true(result.contains("B"))
  assert_true(result.contains("C"))
}
