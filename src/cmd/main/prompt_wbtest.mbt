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
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let output = render_prompt(ctx)

  assert_eq(output, "")
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
