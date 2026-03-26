///|
async test "name" {
  let m : &@ms.PromptModule = RlangModule::default()
  assert_eq(m.name(), "rlang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[rlang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RlangModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-rlang-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RlangModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects DESCRIPTION" {
  let path = "/tmp/moonship-test-rlang-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/DESCRIPTION", "")
  let m = RlangModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no R project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .R extension" {
  let path = "/tmp/moonship-test-rlang-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.R", "")
  let m = RlangModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no R project detected"))
  @test_util.remove_dir_recursive(path)
}


