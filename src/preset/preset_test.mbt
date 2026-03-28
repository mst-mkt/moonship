///|
test "list_presets: returns all 12 presets" {
  let presets = list_presets()
  assert_eq(presets.length(), 12)
}

///|
test "list_presets: sorted alphabetically" {
  let presets = list_presets()
  assert_eq(presets[0], "bracketed-segments")
  assert_eq(presets[11], "tokyo-night")
}

///|
test "list_presets: contains all expected names" {
  let presets = list_presets()
  let expected = [
    "bracketed-segments", "catppuccin-powerline", "gruvbox-rainbow", "jetpack", "nerd-font-symbols",
    "no-empty-icons", "no-nerd-font", "no-runtime-versions", "pastel-powerline",
    "plain-text-symbols", "pure-preset", "tokyo-night",
  ]

  for name in expected {
    assert_true(presets.contains(name))
  }
}

///|
test "get_preset: valid name returns content" {
  for name in list_presets() {
    assert_true(get_preset(name) is Some(_))
  }
}

///|
test "get_preset: unknown name returns None" {
  assert_true(get_preset("nonexistent") is None)
  assert_true(get_preset("") is None)
}

///|
test "get_preset: content is non-empty TOML" {
  for name in list_presets() {
    guard get_preset(name) is Some(content) else {
      fail("expected Some for \{name}")
      continue
    }

    assert_true(content.length() > 0)
  }
}

///|
test "get_preset: bracketed-segments contains format key" {
  guard get_preset("bracketed-segments") is Some(content)
  assert_true(content.contains("format"))
}

///|
test "get_preset: nerd-font-symbols contains symbol key" {
  guard get_preset("nerd-font-symbols") is Some(content)
  assert_true(content.contains("symbol"))
}

///|
test "get_preset: catppuccin-powerline contains palette" {
  guard get_preset("catppuccin-powerline") is Some(content)
  assert_true(content.contains("palettes"))
  assert_true(content.contains("catppuccin_mocha"))
}

///|
test "get_preset: jetpack contains right_format" {
  guard get_preset("jetpack") is Some(content)
  assert_true(content.contains("right_format"))
}

///|
test "get_preset: plain-text-symbols contains continuation_prompt" {
  guard get_preset("plain-text-symbols") is Some(content)
  assert_true(content.contains("continuation_prompt"))
}
