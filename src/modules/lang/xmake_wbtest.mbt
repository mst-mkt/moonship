///|
async test "name" {
  let m : &@ms.PromptModule = XmakeModule::default()
  assert_eq(m.name(), "xmake")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[xmake]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = XmakeModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-xmake-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = XmakeModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects xmake.lua" {
  let path = "/tmp/moonship-test-xmake-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/xmake.lua", "")
  let m = XmakeModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no xmake project detected"))
  @test_util.remove_dir_recursive(path)
}
