///|
async test "name" {
  let m : &@ms.PromptModule = PureScriptModule::default()
  assert_eq(m.name(), "purescript")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[purescript]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PureScriptModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-purescript-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PureScriptModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects spago.dhall" {
  let path = "/tmp/moonship-test-purescript-spago"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/spago.dhall", "")
  let m = PureScriptModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no PureScript project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .purs extension" {
  let path = "/tmp/moonship-test-purescript-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.purs", "")
  let m = PureScriptModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no PureScript project detected"))
  @test_util.remove_dir_recursive(path)
}
