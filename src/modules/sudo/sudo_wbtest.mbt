///|
async test "name" {
  let m : &@ms.PromptModule = SudoModule::new()
  assert_eq(m.name(), "sudo")
}

///|
async test "execute: disabled by default" {
  let m = SudoModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled without cached credentials returns Skipped or Output" {
  let config = @config.Config::from_toml(
    (
      #|[sudo]
      #|disabled = false
    ),
  )
  let m = SudoModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_) || result is Output(_))
}
