///|
async test "name" {
  let m : &@ms.PromptModule = StatusModule::new()
  assert_eq(m.name(), "status")
}

///|
async test "execute: disabled by default" {
  let m = StatusModule::new()
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: success exit code returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=0, config~)
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: non-zero exit code returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=1, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: exit code 127 returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=127, config~)
  assert_true(m.execute(ctx) is Output(_))
}
