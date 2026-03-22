///|
async test "name" {
  let m : &@ms.PromptModule = BatteryModule::default()
  assert_eq(m.name(), "battery")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[battery]
      #|disabled = true
    ),
  )
  let m = BatteryModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_battery_int: standard" {
  assert_eq(parse_battery_int("85"), 85)
}

///|
test "parse_battery_int: with newline" {
  assert_eq(parse_battery_int("42\n"), 42)
}
