///|
async test "name" {
  let m : &@ms.PromptModule = CModule::default()
  assert_eq(m.name(), "c")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[c]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = CModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-c-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = CModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .c extension" {
  let path = "/tmp/moonship-test-c-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.c", "")
  let m = CModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .h extension" {
  let path = "/tmp/moonship-test-c-header"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/lib.h", "")
  let m = CModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C project detected"))
  @test_util.remove_dir_recursive(path)
}
