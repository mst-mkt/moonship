///|
async test "name" {
  let m : &@ms.PromptModule = TimeModule::default()
  assert_eq(m.name(), "time")
}

///|
async test "execute: disabled by default" {
  let m = TimeModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[time]
      #|disabled = false
    ),
  )
  let m = TimeModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let result = m.execute(ctx)
  assert_true(result is Output(_))
}

// --- in_time_range ---

///|
async test "in_time_range: dash means always" {
  assert_true(in_time_range("-"))
}

///|
async test "in_time_range: empty means always" {
  assert_true(in_time_range(""))
}

///|
async test "in_time_range: normal range includes current time" {
  // 00:00-23:59 should always include the current time
  assert_true(in_time_range("00:00-23:59"))
}

///|
async test "in_time_range: range that excludes all times" {
  // No valid HH:MM string is >= "25:00", so this always returns false
  assert_false(in_time_range("25:00-25:01"))
}

///|
async test "in_time_range: invalid format returns true (permissive)" {
  // Single value without dash should return true (guard falls through)
  assert_true(in_time_range("12:00"))
}
