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

///|
test "wrap_ansi_for_zsh: wraps escape sequences" {
  let input = "\u001b[1;31mhello\u001b[0m"
  let result = wrap_ansi_for_zsh(input)
  assert_true(result.contains("%{"))
  assert_true(result.contains("%}"))
  assert_true(result.contains("hello"))
}

///|
test "wrap_ansi_for_zsh: plain text unchanged" {
  assert_eq(wrap_ansi_for_zsh("hello"), "hello")
}

///|
test "wrap_ansi_for_zsh: preserves newline" {
  let input = "line1\n\u001b[1mline2\u001b[0m"
  let result = wrap_ansi_for_zsh(input)
  assert_true(result.contains("\n"))
  assert_true(result.contains("%{"))
}

///|
test "wrap_for_shell: zsh wraps" {
  let input = "\u001b[1mtest\u001b[0m"
  assert_true(wrap_for_shell("zsh", input).contains("%{"))
}

///|
test "wrap_for_shell: fish passes through" {
  let input = "\u001b[1mtest\u001b[0m"
  assert_eq(wrap_for_shell("fish", input), input)
}

///|
test "wrap_ansi_for_zsh: empty string" {
  assert_eq(wrap_ansi_for_zsh(""), "")
}

///|
test "wrap_ansi_for_zsh: multiple sequences each wrapped" {
  let input = "\u001b[1mhello\u001b[0m \u001b[32mworld\u001b[0m"
  let result = wrap_ansi_for_zsh(input)
  assert_eq(
    result, "%{\u001b[1m%}hello%{\u001b[0m%} %{\u001b[32m%}world%{\u001b[0m%}",
  )
}

///|
test "wrap_ansi_for_zsh: text between sequences preserved" {
  let input = "\u001b[1mfoo\u001b[0mbar\u001b[2mbaz\u001b[0m"
  let result = wrap_ansi_for_zsh(input)
  assert_true(result.contains("foo"))
  assert_true(result.contains("bar"))
  assert_true(result.contains("baz"))
}

///|
test "wrap_ansi_for_zsh: incomplete ESC without bracket not wrapped" {
  // ESC followed by a non-bracket char: should not be wrapped
  let input = "\u001bXhello"
  let result = wrap_ansi_for_zsh(input)
  assert_false(result.contains("%{"))
  assert_true(result.contains("hello"))
}

///|
test "wrap_ansi_for_zsh: ESC bracket without m wraps until end" {
  let input = "\u001b[999"
  let result = wrap_ansi_for_zsh(input)
  assert_true(result.contains("%{"))
  assert_true(result.contains("%}"))
}

///|
test "wrap_for_shell: bash passes through" {
  let input = "\u001b[1mtest\u001b[0m"
  assert_eq(wrap_for_shell("bash", input), input)
}

///|
test "wrap_for_shell: zsh wraps sequences" {
  let input = "\u001b[31mred\u001b[0m"
  let result = wrap_for_shell("zsh", input)
  assert_eq(result, "%{\u001b[31m%}red%{\u001b[0m%}")
}

// --- edge cases ---

///|
test "wrap_ansi_for_zsh: no ANSI sequences passes through" {
  assert_eq(wrap_ansi_for_zsh("plain text"), "plain text")
}

///|
test "wrap_ansi_for_zsh: multiple ANSI sequences wrapped" {
  let input = "\u001b[1mbold\u001b[0m \u001b[31mred\u001b[0m"
  let output = wrap_ansi_for_zsh(input)
  assert_true(output.contains("%{"))
  assert_true(output.contains("%}"))
  assert_true(output.contains("bold"))
  assert_true(output.contains("red"))
}

///|
test "wrap_ansi_for_zsh: ESC without bracket not wrapped" {
  let input = "\u001bXtext"
  let output = wrap_ansi_for_zsh(input)
  assert_true(output.contains("text"))
}

///|
test "wrap_for_shell: empty shell name passes through" {
  assert_eq(wrap_for_shell("", "text"), "text")
}

///|
test "escape_fish_single_quote: backslash and quote combined" {
  assert_eq(escape_fish_single_quote("it\\'s"), "it\\\\\\'s")
}
