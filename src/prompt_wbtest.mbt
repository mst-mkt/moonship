///|
async test "render: status 0 green symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
  assert_true(output.contains("32"))
}

///|
async test "render: status 1 red symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
  assert_true(output.contains("31"))
}

///|
async test "render: all referenced modules disabled produces empty" {
  let config = @config.Config::from_toml(
    (
      #|format = "$character$directory$line_break"
      #|[character]
      #|disabled = true
      #|[directory]
      #|disabled = true
      #|[line_break]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_eq(output, "")
}

///|
async test "render: includes directory" {
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
  )
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("project"))
}

///|
async test "pad_right: shorter than width" {
  assert_eq(pad_right("abc", 6), "abc   ")
}

///|
async test "pad_right: equal to width" {
  assert_eq(pad_right("abc", 3), "abc")
}

///|
async test "pad_right: longer than width" {
  assert_eq(pad_right("abcdef", 3), "abcdef")
}

///|
async test "pad_left: shorter than width" {
  assert_eq(pad_left("abc", 6), "   abc")
}

///|
async test "pad_left: equal to width" {
  assert_eq(pad_left("abc", 3), "abc")
}

///|
async test "pad_left: longer than width" {
  assert_eq(pad_left("abcdef", 3), "abcdef")
}

///|
async test "format_duration: zero" {
  assert_eq(format_duration(0L), "<1ms")
}

///|
async test "format_duration: nonzero" {
  assert_eq(format_duration(5L), "5ms")
  assert_eq(format_duration(123L), "123ms")
}

///|
async test "render: non-git directory has character but no git branch" {
  let ctx = @context.Context::new(cwd="/tmp", home_dir="/tmp")
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
  // git_branch uses purple (ANSI 35). In /tmp there is no git repo,
  // so git_branch returns Skipped and no purple styling should appear.
  assert_false(output.contains(";35m"))
}

///|
async test "render: custom format with single module excludes others" {
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
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
  // directory is not in format, so "project" should not appear
  assert_false(output.contains("project"))
}

///|
async test "render: custom format ordering" {
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
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
  assert_true(output.contains("project"))
}

///|
async test "replace_var: basic" {
  assert_eq(replace_var("$all", "all", "XY"), "XY")
}

///|
async test "replace_var: does not match prefix" {
  assert_eq(replace_var("$all_status", "all", "XY"), "$all_status")
}

///|
async test "replace_var: matches at end" {
  assert_eq(replace_var("prefix$all", "all", "XY"), "prefixXY")
}

///|
async test "replace_var: with surrounding modules" {
  assert_eq(
    replace_var("$directory$all$character", "all", "$git_branch"),
    "$directory$git_branch$character",
  )
}

///|
async test "expand_all: includes registered modules" {
  let modules = build_modules(@config.Config::default())
  let format = expand_all("$all", modules)

  assert_true(format.contains("$directory"))
  assert_true(format.contains("$character"))
  assert_false(format.contains("$all"))
}

///|
async test "expand_all: excludes explicit modules" {
  let modules = build_modules(@config.Config::default())
  let format = expand_all("$directory$all", modules)

  assert_true(format.contains("$character"))
  // directory is already explicit, should not appear twice
  let count = format.split("$directory").fold(init=0, fn(n, _) { n + 1 }) - 1
  assert_eq(count, 1)
}

///|
async test "expand_all: no $all returns unchanged" {
  let modules = build_modules(@config.Config::default())
  let format = "$directory$character"
  assert_eq(expand_all(format, modules), format)
}

// --- replace_var: additional edge cases ---

///|
async test "replace_var: no match" {
  assert_eq(replace_var("$other", "all", "XY"), "$other")
}

///|
async test "replace_var: multiple occurrences" {
  assert_eq(replace_var("$all$all", "all", "X"), "XX")
}

///|
async test "replace_var: empty string" {
  assert_eq(replace_var("", "all", "XY"), "")
}

///|
async test "replace_var: replacement with empty string" {
  assert_eq(replace_var("a$all b", "all", ""), "a b")
}

///|
async test "replace_var: partial match does not replace" {
  assert_eq(replace_var("$allison", "all", "XY"), "$allison")
}

// --- starts_with_at ---

///|
async test "starts_with_at: basic match" {
  assert_true(starts_with_at("hello world", 0, "hello"))
}

///|
async test "starts_with_at: match at offset" {
  assert_true(starts_with_at("hello world", 6, "world"))
}

///|
async test "starts_with_at: no match" {
  assert_false(starts_with_at("hello world", 0, "world"))
}

///|
async test "starts_with_at: offset at end" {
  assert_false(starts_with_at("hello", 5, "x"))
}

///|
async test "starts_with_at: empty prefix" {
  assert_true(starts_with_at("hello", 0, ""))
}

///|
async test "starts_with_at: prefix longer than remaining" {
  assert_false(starts_with_at("hi", 1, "hello"))
}

///|
async test "starts_with_at: exact match at offset" {
  assert_true(starts_with_at("abcdef", 3, "def"))
}

///|
async test "render: unknown module skipped" {
  let config = @config.Config::from_toml(
    (
      #|format = "$nonexistent$character"
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let output = render_prompt(ctx, build_modules(ctx.config))

  assert_true(output.contains("❯"))
}
