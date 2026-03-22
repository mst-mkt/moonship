///|
async test "name" {
  let m : &@ms.PromptModule = TimeModule::default()
  assert_eq(m.name(), "time")
}

///|
async test "execute: disabled by default" {
  let m = TimeModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[time]
      #|disabled = false
    ),
  )
  let m = TimeModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let result = m.execute(ctx)
  assert_true(result is Output(_))
}
