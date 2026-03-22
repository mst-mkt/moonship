///|
async test "name" {
  let m : &@ms.PromptModule = EnvVarModule::default()
  assert_eq(m.name(), "env_var")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|disabled = true
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no variable configured returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|disabled = false
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Skipped(_))
}
