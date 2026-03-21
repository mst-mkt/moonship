///|
async test "name" {
  let m : &@ms.PromptModule = MesonModule::new()
  assert_eq(m.name(), "meson")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[meson]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = MesonModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: not in devenv returns Skipped" {
  let m = MesonModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
}
