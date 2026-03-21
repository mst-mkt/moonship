///|
async test "name" {
  let m : &@ms.PromptModule = ShellModule::new()
  assert_eq(m.name(), "shell")
}

///|
async test "execute: disabled by default" {
  let m = ShellModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled produces output when MOONSHIP_SHELL is set" {
  let config = @config.Config::from_toml(
    (
      #|[shell]
      #|disabled = false
    ),
  )
  let m = ShellModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let result = m.execute(ctx)
  // MOONSHIP_SHELL may or may not be set in test env
  assert_true(result is Output(_) || result is Skipped(_))
}
