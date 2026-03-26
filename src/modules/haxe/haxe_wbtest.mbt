///|
async test "name" {
  let m : &@ms.PromptModule = HaxeModule::default()
  assert_eq(m.name(), "haxe")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[haxe]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = HaxeModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-haxe-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = HaxeModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects haxelib.json" {
  let path = "/tmp/moonship-test-haxe-lib"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/haxelib.json", "")
  let m = HaxeModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haxe project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .hx extension" {
  let path = "/tmp/moonship-test-haxe-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.hx", "")
  let m = HaxeModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haxe project detected"))
  @test_util.remove_dir_recursive(path)
}


