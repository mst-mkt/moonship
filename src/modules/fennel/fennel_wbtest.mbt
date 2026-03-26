///|
async test "name" {
  let m : &@ms.PromptModule = FennelModule::default()
  assert_eq(m.name(), "fennel")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[fennel]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = FennelModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: detects .fnl extension" {
  let path = "/tmp/moonship-test-fennel-fnl"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/init.fnl", "")
  let m = FennelModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Fennel project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_fennel_version: typical output" {
  assert_eq(parse_fennel_version("Fennel 1.3.1"), "1.3.1")
}

///|
test "parse_fennel_version: empty" {
  assert_eq(parse_fennel_version(""), "")
}


