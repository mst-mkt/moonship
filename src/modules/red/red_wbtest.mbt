///|
async test "name" {
  let m : &@ms.PromptModule = RedModule::default()
  assert_eq(m.name(), "red")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[red]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RedModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-red-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RedModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .red extension" {
  let path = "/tmp/moonship-test-red-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.red", "")
  let m = RedModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Red project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_red_version: typical output" {
  assert_eq(parse_red_version("Red 0.6.4"), "0.6.4")
}

///|
test "parse_red_version: empty" {
  assert_eq(parse_red_version(""), "")
}


