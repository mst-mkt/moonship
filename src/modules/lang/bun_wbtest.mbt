///|
async test "name" {
  let m : &@ms.PromptModule = BunModule::default()
  assert_eq(m.name(), "bun")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[bun]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = BunModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-bun-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = BunModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects bun.lock" {
  let path = "/tmp/moonship-test-bun-lock"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/bun.lock", "")
  let m = BunModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Bun project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects bun.lockb" {
  let path = "/tmp/moonship-test-bun-lockb"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/bun.lockb", "")
  let m = BunModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Bun project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects bunfig.toml" {
  let path = "/tmp/moonship-test-bun-bunfig"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/bunfig.toml", "")
  let m = BunModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Bun project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
