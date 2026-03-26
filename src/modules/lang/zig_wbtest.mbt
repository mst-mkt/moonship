///|
async test "name" {
  let m : &@ms.PromptModule = ZigModule::default()
  assert_eq(m.name(), "zig")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[zig]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ZigModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-zig-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ZigModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .zig extension" {
  let path = "/tmp/moonship-test-zig-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.zig", "")
  let m = ZigModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Zig project detected"))
  @test_util.remove_dir_recursive(path)
}
