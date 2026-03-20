///|
test "name" {
  let m : &@ms.PromptModule = CmdDurationModule::new()
  assert_eq(m.name(), "cmd_duration")
}

// --- format_duration ---

///|
test "format_duration: milliseconds" {
  assert_eq(format_duration(500), "500ms")
}

///|
test "format_duration: seconds" {
  assert_eq(format_duration(5000), "5s")
}

///|
test "format_duration: minutes and seconds" {
  assert_eq(format_duration(90000), "1m30s")
}

///|
test "format_duration: hours" {
  assert_eq(format_duration(3661000), "1h1m1s")
}

///|
test "format_duration: exact boundary" {
  assert_eq(format_duration(1000), "1s")
  assert_eq(format_duration(999), "999ms")
}

// --- execute ---

///|
test "execute: below min_time returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp", cmd_duration=1000)
  let m = CmdDurationModule::new()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
test "execute: above min_time returns Output" {
  let ctx = @context.Context::new(cwd="/tmp", cmd_duration=5000)
  let m = CmdDurationModule::new()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  assert_true(out.render().contains("5s"))
}

///|
test "execute: custom min_time" {
  let config = @config.Config::from_toml(
    (
      #|[cmd_duration]
      #|min_time = 500
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", cmd_duration=600, config~)
  let m = CmdDurationModule::from_config(config)
  assert_true(m.execute(ctx) is Output(_))
}

///|
test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[cmd_duration]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", cmd_duration=5000, config~)
  let m = CmdDurationModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}
