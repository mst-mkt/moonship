///|
async test "name" {
  let m : &@ms.PromptModule = RakuModule::default()
  assert_eq(m.name(), "raku")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[raku]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RakuModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-raku-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RakuModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects META6.json" {
  let path = "/tmp/moonship-test-raku-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/META6.json", "")
  let m = RakuModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Raku project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .raku extension" {
  let path = "/tmp/moonship-test-raku-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.raku", "")
  let m = RakuModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Raku project detected"))
  @test_util.remove_dir_recursive(path)
}


