///|
async test "name" {
  let m : &@ms.PromptModule = SudoModule::default()
  assert_eq(m.name(), "sudo")
}

///|
async test "execute: disabled by default" {
  let m = SudoModule::default()
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
  assert_true(not(result is Disabled))
}

// --- allow_windows ---

///|
test "default: allow_windows is false" {
  let m = SudoModule::default()
  assert_eq(m.allow_windows, false)
}

///|
test "from_table: allow_windows parsed" {
  let config = @config.Config::from_toml(
    (
      #|[sudo]
      #|allow_windows = true
    ),
  )
  let m = SudoModule::from_config(config)
  assert_eq(m.allow_windows, true)
}
