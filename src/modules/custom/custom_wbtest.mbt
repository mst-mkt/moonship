///|
async test "name" {
  let m : &@ms.PromptModule = CustomModule::default()
  assert_eq(m.name(), "custom")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|disabled = true
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no command returns Skipped" {
  let m = CustomModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Skipped(_))
}
