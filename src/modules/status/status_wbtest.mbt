///|
async test "name" {
  let m : &@ms.PromptModule = StatusModule::default()
  assert_eq(m.name(), "status")
}

///|
async test "execute: disabled by default" {
  let m = StatusModule::default()
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: success exit code returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=0, config~)
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: non-zero exit code returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=1, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: exit code 127 returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", status=127, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: pipestatus with multiple codes" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=1,
    pipestatus=["0", "1", "0"],
    config~,
  )

  guard m.execute(ctx) is Output(out) else {
    fail("Expected Output")
    return
  }

  let rendered = out.render()
  assert_true(rendered.contains("0"))
  assert_true(rendered.contains("1"))
}

///|
async test "execute: pipestatus disabled uses normal format" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = false
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=1,
    pipestatus=["0", "1"],
    config~,
  )

  guard m.execute(ctx) is Output(_) else {
    fail("Expected Output")
    return
  }
}

///|
async test "execute: pipestatus single element uses normal format" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=1,
    pipestatus=["1"],
    config~,
  )

  guard m.execute(ctx) is Output(_) else {
    fail("Expected Output")
    return
  }
}

///|
test "build_status_vars: common meanings" {
  let m = StatusModule::default()

  let vars1 = m.build_status_vars(1)
  assert_eq(vars1.get("common_meaning"), Some("ERROR"))

  let vars126 = m.build_status_vars(126)
  assert_eq(vars126.get("common_meaning"), Some("NOPERM"))

  let vars127 = m.build_status_vars(127)
  assert_eq(vars127.get("common_meaning"), Some("NOTFOUND"))
}

///|
test "build_status_vars: signal names" {
  let m = StatusModule::default()

  let vars = m.build_status_vars(130)
  assert_eq(vars.get("signal_name"), Some("INT"))
  assert_eq(vars.get("signal_number"), Some("2"))

  let vars139 = m.build_status_vars(139)
  assert_eq(vars139.get("signal_name"), Some("SEGV"))
}

///|
test "build_status_vars: hex status" {
  let m = StatusModule::default()

  let vars = m.build_status_vars(127)
  assert_eq(vars.get("hex_status"), Some("0x7F"))

  let vars0 = m.build_status_vars(0)
  assert_eq(vars0.get("hex_status"), Some("0x0"))
}

///|
async test "execute: pipestatus with status=0 but pipe segment failed" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=0,
    pipestatus=["0", "1", "0"],
    config~,
  )

  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: pipestatus separator in output" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
      #|pipestatus_separator = " | "
      #|pipestatus_segment_format = "$status"
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=1,
    pipestatus=["0", "1"],
    config~,
  )

  guard m.execute(ctx) is Output(out) else {
    fail("Expected Output")
    return
  }

  let rendered = out.render()
  assert_true(rendered.contains(" | "))
}

///|
async test "execute: pipestatus with custom segment format" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
      #|pipestatus_segment_format = "[$status]($style)"
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=1,
    pipestatus=["0", "127"],
    config~,
  )

  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: pipestatus with map_symbol" {
  let config = @config.Config::from_toml(
    (
      #|[status]
      #|disabled = false
      #|pipestatus = true
      #|map_symbol = true
      #|pipestatus_segment_format = "$symbol"
    ),
  )
  let m = StatusModule::from_config(config)
  let ctx = @context.Context::new(
    cwd="/tmp",
    status=127,
    pipestatus=["0", "127"],
    config~,
  )

  guard m.execute(ctx) is Output(out) else {
    fail("Expected Output")
    return
  }

  let rendered = out.render()
  assert_true(rendered.contains("🔍"))
}

///|
test "build_status_vars: sigint symbol for exit code 130" {
  let m = { ..StatusModule::default(), map_symbol: true }
  let vars = m.build_status_vars(130)
  assert_eq(vars.get("symbol"), Some("🧱"))
}

///|
test "build_status_vars: signal symbol for exit code 137 (KILL)" {
  let m = { ..StatusModule::default(), map_symbol: true }
  let vars = m.build_status_vars(137)
  assert_eq(vars.get("symbol"), Some("⚡"))
}

///|
test "build_status_vars: recognize_signal_code=false uses normal symbol" {
  let m = {
    ..StatusModule::default(),
    map_symbol: true,
    recognize_signal_code: false,
  }
  let vars = m.build_status_vars(130)
  assert_eq(vars.get("symbol"), Some("❌"))
}

///|
test "build_status_vars: success_style overrides style" {
  let m = { ..StatusModule::default(), success_style: "bold green" }
  let vars = m.build_status_vars(0)
  assert_eq(vars.get("style"), Some("bold green"))
}

///|
test "build_status_vars: failure_style overrides style" {
  let m = { ..StatusModule::default(), failure_style: "bold yellow" }
  let vars = m.build_status_vars(1)
  assert_eq(vars.get("style"), Some("bold yellow"))
}

///|
test "build_status_vars: recognize_signal_code=false clears signal_name" {
  let m = {
    ..StatusModule::default(),
    recognize_signal_code: false,
  }
  let vars = m.build_status_vars(130)
  assert_eq(vars.get("signal_name"), Some(""))
  assert_eq(vars.get("signal_number"), Some(""))
  assert_eq(vars.get("maybe_int"), Some("130"))
}

///|
test "build_status_vars: failure_style on signal exit code" {
  let m = { ..StatusModule::default(), failure_style: "bold magenta" }
  let vars = m.build_status_vars(130)
  assert_eq(vars.get("style"), Some("bold magenta"))
}

///|
test "build_status_vars: no style override uses default" {
  let m = StatusModule::default()
  let vars = m.build_status_vars(1)
  assert_eq(vars.get("style"), Some("bold red"))
}

///|
test "hex_string" {
  assert_eq(hex_string(0), "0")
  assert_eq(hex_string(15), "F")
  assert_eq(hex_string(16), "10")
  assert_eq(hex_string(255), "FF")
  assert_eq(hex_string(127), "7F")
}
