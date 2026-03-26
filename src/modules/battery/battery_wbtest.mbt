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

// --- display rules ---

///|
test "parse_display_rules: from TOML array" {
  let config = @config.Config::from_toml(
    (
      #|[battery]
      #|
      #|[[battery.display]]
      #|threshold = 10
      #|style = "bold red"
      #|
      #|[[battery.display]]
      #|threshold = 30
      #|style = "bold yellow"
    ),
  )
  let m = BatteryModule::from_config(config)

  assert_eq(m.display.length(), 2)
  assert_eq(m.display[0].threshold, 10)
  assert_eq(m.display[0].style, "bold red")
  assert_eq(m.display[1].threshold, 30)
  assert_eq(m.display[1].style, "bold yellow")
}

///|
test "parse_display_rules: with per-threshold symbols" {
  let config = @config.Config::from_toml(
    (
      #|[battery]
      #|
      #|[[battery.display]]
      #|threshold = 15
      #|style = "bold red"
      #|charging_symbol = "⚡"
      #|discharging_symbol = "💀"
    ),
  )
  let m = BatteryModule::from_config(config)

  assert_eq(m.display.length(), 1)
  assert_eq(m.display[0].charging_symbol, "⚡")
  assert_eq(m.display[0].discharging_symbol, "💀")
}

///|
test "parse_display_rules: defaults when no display configured" {
  let config = @config.Config::from_toml(
    (
      #|[battery]
      #|disabled = false
    ),
  )
  let m = BatteryModule::from_config(config)

  // Default: one rule at threshold 10
  assert_eq(m.display.length(), 1)
  assert_eq(m.display[0].threshold, 10)
  assert_eq(m.display[0].style, "red bold")
}

///|
test "default: single display rule at threshold 10" {
  let m = BatteryModule::default()
  assert_eq(m.display.length(), 1)
  assert_eq(m.display[0].threshold, 10)
}
