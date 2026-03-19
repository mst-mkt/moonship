///|
test "Shell::from_string: valid" {
  assert_true(@shell.Shell::from_string("zsh") is Some(@shell.Zsh))
  assert_true(@shell.Shell::from_string("bash") is Some(@shell.Bash))
  assert_true(@shell.Shell::from_string("fish") is Some(@shell.Fish))
}

///|
test "Shell::from_string: invalid" {
  assert_true(@shell.Shell::from_string("powershell") is None)
  assert_true(@shell.Shell::from_string("") is None)
}

///|
test "generate_init: zsh" {
  let script = @shell.generate_init(@shell.Zsh, "/usr/local/bin/moonship")
  assert_true(script.contains("MOONSHIP_BIN='/usr/local/bin/moonship'"))
  assert_true(script.contains("precmd"))
  assert_true(script.contains("preexec"))
}

///|
test "generate_init: bash" {
  let script = @shell.generate_init(@shell.Bash, "/usr/local/bin/moonship")
  assert_true(script.contains("PROMPT_COMMAND"))
  assert_true(script.contains("DEBUG"))
}

///|
test "generate_init: fish" {
  let script = @shell.generate_init(@shell.Fish, "/usr/local/bin/moonship")
  assert_true(script.contains("fish_prompt"))
  assert_true(script.contains("fish_preexec"))
}

///|
test "generate_init: escape single quote in zsh" {
  let script = @shell.generate_init(@shell.Zsh, "/opt/it's here/moonship")
  assert_true(script.contains("MOONSHIP_BIN='/opt/it'\\''s here/moonship'"))
}

///|
test "generate_init: escape single quote in bash" {
  let script = @shell.generate_init(@shell.Bash, "/opt/it's here/moonship")
  assert_true(script.contains("MOONSHIP_BIN='/opt/it'\\''s here/moonship'"))
}

///|
test "generate_init: escape backslash in fish" {
  let script = @shell.generate_init(@shell.Fish, "/path\\bin/moonship")
  assert_true(script.contains("\\\\"))
}

///|
test "Shell::to_string" {
  assert_eq(@shell.Zsh.to_string(), "zsh")
  assert_eq(@shell.Bash.to_string(), "bash")
  assert_eq(@shell.Fish.to_string(), "fish")
}
