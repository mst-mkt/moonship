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
