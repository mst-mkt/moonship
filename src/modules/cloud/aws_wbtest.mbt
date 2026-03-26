///|
async test "name" {
  let m : &@ms.PromptModule = AwsModule::default()
  assert_eq(m.name(), "aws")
}

///|
async test "execute: no aws env returns Skipped" {
  let m = AwsModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(not(result is Disabled))
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[aws]
      #|disabled = true
    ),
  )
  let m = AwsModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}
