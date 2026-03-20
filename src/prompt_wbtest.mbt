///|
test "render: status 0 green symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  assert_true(output.contains("32"))
}

///|
test "render: status 1 red symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  assert_true(output.contains("31"))
}

///|
test "render: all disabled produces empty" {
  let config = @config.Config::from_toml(
    (
      #|[character]
      #|disabled = true
      #|[directory]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let output = render_prompt(ctx)

  assert_eq(output, "\n")
}

///|
test "render: includes directory" {
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
  )
  let output = render_prompt(ctx)

  assert_true(output.contains("project"))
}

///|
test "pad_right: shorter than width" {
  assert_eq(pad_right("abc", 6), "abc   ")
}

///|
test "pad_right: equal to width" {
  assert_eq(pad_right("abc", 3), "abc")
}

///|
test "pad_right: longer than width" {
  assert_eq(pad_right("abcdef", 3), "abcdef")
}

///|
test "pad_left: shorter than width" {
  assert_eq(pad_left("abc", 6), "   abc")
}

///|
test "pad_left: equal to width" {
  assert_eq(pad_left("abc", 3), "abc")
}

///|
test "pad_left: longer than width" {
  assert_eq(pad_left("abcdef", 3), "abcdef")
}

///|
test "format_duration: zero" {
  assert_eq(format_duration(0L), "<1ms")
}

///|
test "format_duration: nonzero" {
  assert_eq(format_duration(5L), "5ms")
  assert_eq(format_duration(123L), "123ms")
}

///|
test "render: non-git directory has character but no git branch" {
  let ctx = @context.Context::new(cwd="/tmp", home_dir="/tmp")
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  // git_branch uses purple (ANSI 35). In /tmp there is no git repo,
  // so git_branch returns Skipped and no purple styling should appear.
  assert_false(output.contains(";35m"))
}

///|
test "render: custom format with single module excludes others" {
  let config = @config.Config::from_toml(
    (
      #|format = "$character"
    ),
  )
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
    config~,
  )
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  // directory is not in format, so "project" should not appear
  assert_false(output.contains("project"))
}

///|
test "render: custom format ordering" {
  let config = @config.Config::from_toml(
    (
      #|format = "$character $directory"
    ),
  )
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
    config~,
  )
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  assert_true(output.contains("project"))
}

///|
test "render: unknown module skipped" {
  let config = @config.Config::from_toml(
    (
      #|format = "$nonexistent$character"
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
}
