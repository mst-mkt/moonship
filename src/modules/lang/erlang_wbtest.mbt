///|
async test "name" {
  let m : &@ms.PromptModule = ErlangModule::default()
  assert_eq(m.name(), "erlang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[erlang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ErlangModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-erlang-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ErlangModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects rebar.config" {
  let path = "/tmp/moonship-test-erlang-rebar"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/rebar.config", "")
  let m = ErlangModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Erlang project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects erlang.mk" {
  let path = "/tmp/moonship-test-erlang-mk"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/erlang.mk", "")
  let m = ErlangModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Erlang project detected"))
  @test_util.remove_dir_recursive(path)
}
