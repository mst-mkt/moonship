///|
async test "name" {
  let m : &@ms.PromptModule = NodejsModule::new()
  assert_eq(m.name(), "nodejs")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[nodejs]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = NodejsModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = NodejsModule::new()
  assert_true(m.execute(ctx) is Skipped(_))
}
