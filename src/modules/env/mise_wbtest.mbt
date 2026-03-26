///|
async test "name" {
  let m : &@ms.PromptModule = MiseModule::default()
  assert_eq(m.name(), "mise")
}

///|
async test "execute: disabled by default" {
  let m = MiseModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no mise files returns Skipped" {
  let path = "/tmp/moonship-test-mise-empty"
  @test_util.setup_dir(path)
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects mise.toml" {
  let path = "/tmp/moonship-test-mise-toml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/mise.toml", "")
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  guard not(result is Skipped("no mise project detected")) else {
    fail("expected mise.toml to be detected, but got Skipped")
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .mise.toml" {
  let path = "/tmp/moonship-test-mise-dottoml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.mise.toml", "")
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  guard not(result is Skipped("no mise project detected")) else {
    fail("expected .mise.toml to be detected, but got Skipped")
  }
  @test_util.remove_dir_recursive(path)
}
