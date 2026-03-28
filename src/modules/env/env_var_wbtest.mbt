///|
async test "name" {
  let m : &@ms.PromptModule = EnvVarModule::default()
  assert_eq(m.name(), "env_var")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|disabled = true
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no variable configured returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|disabled = false
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: variable set produces output" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|variable = "HOME"
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output")
    return
  }

  assert_true(out.render().length() > 0)
}

///|
async test "execute: default_value used when env var not set" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|variable = "MOONSHIP_TEST_NONEXISTENT_VAR"
      #|default = "fallback_value"
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("fallback_value"))
}

///|
async test "execute: unset var without default returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[env_var]
      #|variable = "MOONSHIP_TEST_NONEXISTENT_VAR"
    ),
  )
  let m = EnvVarModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Skipped(_))
}

// --- named instance (env_var.NAME) ---

///|
test "from_named_config: name and variable derived from instance name" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.VIMSHELL]
      #|default = "unknown"
    ),
  )
  let m = EnvVarModule::from_named_config(config, "VIMSHELL")
  assert_eq(m.module_name, "env_var.VIMSHELL")
  assert_eq(m.variable, "VIMSHELL")
  assert_eq(m.default_value, "unknown")
}

///|
test "from_named_config: explicit variable overrides instance name" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.MY_VAR]
      #|variable = "ACTUAL_VAR"
    ),
  )
  let m = EnvVarModule::from_named_config(config, "MY_VAR")
  assert_eq(m.module_name, "env_var.MY_VAR")
  assert_eq(m.variable, "ACTUAL_VAR")
}

///|
test "from_named_config: inherits defaults for missing fields" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.HOME]
    ),
  )
  let m = EnvVarModule::from_named_config(config, "HOME")
  let d = EnvVarModule::default()
  assert_eq(m.module_name, "env_var.HOME")
  assert_eq(m.variable, "HOME")
  assert_eq(m.format, d.format)
  assert_eq(m.style, d.style)
  assert_eq(m.symbol, d.symbol)
  assert_eq(m.disabled, false)
}

///|
test "from_named_config: nonexistent child uses defaults" {
  let config = @config.Config::default()
  let m = EnvVarModule::from_named_config(config, "MISSING")
  assert_eq(m.module_name, "env_var.MISSING")
  assert_eq(m.variable, "MISSING")
}

///|
test "from_named_config: custom format and style" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.SHELL]
      #|format = "[$symbol$env_value]($style)"
      #|style = "bold green"
      #|symbol = "🐚 "
    ),
  )
  let m = EnvVarModule::from_named_config(config, "SHELL")
  assert_eq(m.format, "[$symbol$env_value]($style)")
  assert_eq(m.style, "bold green")
  assert_eq(m.symbol, "🐚 ")
  assert_eq(m.variable, "SHELL")
}

///|
async test "from_named_config: named instance executes correctly" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.HOME]
    ),
  )
  let m = EnvVarModule::from_named_config(config, "HOME")
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output for HOME")
    return
  }

  assert_true(out.render().length() > 0)
}

///|
async test "from_named_config: disabled named instance" {
  let config = @config.Config::from_toml(
    (
      #|[env_var.MY_VAR]
      #|disabled = true
    ),
  )
  let m = EnvVarModule::from_named_config(config, "MY_VAR")
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}
