///|
async test "name" {
  let m : &@ms.PromptModule = GcloudModule::new()
  assert_eq(m.name(), "gcloud")
}

///|
async test "execute: no gcloud env returns Skipped" {
  let m = GcloudModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_) || result is Output(_))
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[gcloud]
      #|disabled = true
    ),
  )
  let m = GcloudModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}
