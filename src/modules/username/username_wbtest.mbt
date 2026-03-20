///|
test "name" {
  let m : &@ms.PromptModule = UsernameModule::new()
  assert_eq(m.name(), "username")
}

// --- execute ---

///|
test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[username]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = UsernameModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "execute: show_always shows username" {
  let config = @config.Config::from_toml(
    (
      #|[username]
      #|show_always = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = UsernameModule::from_config(config)

  // USER env var should be set in test environment
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.length() > 0)
}

///|
test "execute: default hides for normal user" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = UsernameModule::new()

  // In normal test environment (not root, not SSH), should be Skipped
  assert_true(m.execute(ctx) is Skipped(_))
}
