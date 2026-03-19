///|
test "escape_shell_single_quote: no quotes" {
  assert_eq(escape_shell_single_quote("/usr/bin/moonship"), "/usr/bin/moonship")
}

///|
test "escape_shell_single_quote: with quote" {
  assert_eq(
    escape_shell_single_quote("/opt/it's here/bin"),
    "/opt/it'\\''s here/bin",
  )
}

///|
test "escape_fish_single_quote: no special chars" {
  assert_eq(escape_fish_single_quote("/usr/bin/moonship"), "/usr/bin/moonship")
}

///|
test "escape_fish_single_quote: with quote" {
  assert_eq(
    escape_fish_single_quote("/opt/it's here/bin"),
    "/opt/it\\'s here/bin",
  )
}

///|
test "escape_fish_single_quote: with backslash" {
  assert_true(escape_fish_single_quote("/path\\here").contains("\\\\"))
}
