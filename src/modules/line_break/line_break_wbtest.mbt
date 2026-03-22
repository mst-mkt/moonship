///|
async test "name" {
  let m : &@ms.PromptModule = LineBreakModule::default()
  assert_eq(m.name(), "line_break")
}

///|
async test "execute: outputs newline" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = LineBreakModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  assert_eq(out.render(), "\n")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[line_break]
      #|disabled = true
    ),
  )
  let m = LineBreakModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}
