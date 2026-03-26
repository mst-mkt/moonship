///|
async test "name" {
  let m : &@ms.PromptModule = PixiModule::default()
  assert_eq(m.name(), "pixi")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[pixi]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PixiModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-pixi-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PixiModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects pixi.toml" {
  let path = "/tmp/moonship-test-pixi-toml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/pixi.toml", "")
  let m = PixiModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Pixi project detected")) else {
    fail("expected pixi.toml to be detected, but got Skipped")
  }
  @test_util.remove_dir_recursive(path)
}
