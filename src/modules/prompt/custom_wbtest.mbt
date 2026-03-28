///|
async test "name" {
  let m : &@ms.PromptModule = CustomModule::default()
  assert_eq(m.name(), "custom")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|disabled = true
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no command returns Skipped" {
  let m = CustomModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: command produces output" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo hello"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("hello"))
}

///|
async test "execute: when condition filters module" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo visible"
      #|when = "false"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  // "false" command returns exit 1 and empty output, so when condition fails
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: when condition passes with exit 0 (no output)" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo visible"
      #|when = "true"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  // "true" exits 0 but produces no output -- should still pass
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: when condition passes with exit 0 and output" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo visible"
      #|when = "echo yes"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: detect_files skips when no match" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo test"
      #|detect_files = ["nonexistent-file-xyz.txt"]
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: custom shell" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo custom_shell"
      #|shell = "bash"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("custom_shell"))
}

///|
async test "execute: require_repo skips when not in repo" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo test"
      #|require_repo = true
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: os=windows skips on linux" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo test"
      #|os = "windows"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: os=linux runs on linux" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo test"
      #|os = "linux"
    ),
  )
  let m = CustomModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Output(_))
}

///|
test "from_table: all fields parsed" {
  let config = @config.Config::from_toml(
    (
      #|[custom]
      #|command = "echo test"
      #|when = "true"
      #|shell = "bash"
      #|description = "test module"
      #|detect_files = ["Makefile"]
      #|detect_extensions = [".mk"]
    ),
  )
  let m = CustomModule::from_config(config)

  assert_eq(m.command, "echo test")
  assert_eq(m.when, "true")
  assert_eq(m.shell, "bash")
  assert_eq(m.description, "test module")
  assert_eq(m.detect_files, ["Makefile"])
  assert_eq(m.detect_extensions, [".mk"])
}

// --- named instance (custom.NAME) ---

///|
test "from_named_config: name is dotted" {
  let config = @config.Config::from_toml(
    (
      #|[custom.my_cmd]
      #|command = "echo hello"
    ),
  )
  let m = CustomModule::from_named_config(config, "my_cmd")
  assert_eq(m.module_name, "custom.my_cmd")
  assert_eq(m.command, "echo hello")
}

///|
test "from_named_config: inherits defaults" {
  let config = @config.Config::from_toml(
    (
      #|[custom.minimal]
      #|command = "echo test"
    ),
  )
  let m = CustomModule::from_named_config(config, "minimal")
  let d = CustomModule::default()
  assert_eq(m.module_name, "custom.minimal")
  assert_eq(m.format, d.format)
  assert_eq(m.style, d.style)
  assert_eq(m.disabled, false)
}

///|
test "from_named_config: nonexistent child uses defaults" {
  let config = @config.Config::default()
  let m = CustomModule::from_named_config(config, "missing")
  assert_eq(m.module_name, "custom.missing")
  assert_eq(m.command, "")
}

///|
test "from_named_config: all fields parsed" {
  let config = @config.Config::from_toml(
    (
      #|[custom.full]
      #|command = "echo full"
      #|when = "true"
      #|shell = "bash"
      #|description = "full module"
      #|detect_files = ["Makefile"]
      #|detect_extensions = [".mk"]
      #|detect_folders = ["build"]
      #|require_repo = true
      #|os = "linux"
      #|symbol = "★ "
      #|style = "bold blue"
      #|format = "[$output]($style)"
    ),
  )
  let m = CustomModule::from_named_config(config, "full")
  assert_eq(m.module_name, "custom.full")
  assert_eq(m.command, "echo full")
  assert_eq(m.when, "true")
  assert_eq(m.shell, "bash")
  assert_eq(m.description, "full module")
  assert_eq(m.detect_files, ["Makefile"])
  assert_eq(m.detect_extensions, [".mk"])
  assert_eq(m.detect_folders, ["build"])
  assert_eq(m.require_repo, true)
  assert_eq(m.os, "linux")
  assert_eq(m.symbol, "★ ")
  assert_eq(m.style, "bold blue")
  assert_eq(m.format, "[$output]($style)")
}

///|
async test "from_named_config: named instance executes" {
  let config = @config.Config::from_toml(
    (
      #|[custom.hello]
      #|command = "echo hello_named"
    ),
  )
  let m = CustomModule::from_named_config(config, "hello")
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("hello_named"))
}

///|
async test "from_named_config: disabled named instance" {
  let config = @config.Config::from_toml(
    (
      #|[custom.disabled_cmd]
      #|command = "echo test"
      #|disabled = true
    ),
  )
  let m = CustomModule::from_named_config(config, "disabled_cmd")
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}
