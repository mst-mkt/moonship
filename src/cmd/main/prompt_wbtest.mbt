///|
test "render_prompt: status 0 で緑のシンボル" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  assert_true(output.contains("32")) // green
}

///|
test "render_prompt: status 1 で赤のシンボル" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let output = render_prompt(ctx)

  assert_true(output.contains("❯"))
  assert_true(output.contains("31")) // red
}

///|
test "render_prompt: 全モジュール無効で空出力" {
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
test "render_prompt: 未知のモジュールはスキップ" {
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
