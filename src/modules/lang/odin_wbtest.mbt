///|
async test "name" {
  let m : &@ms.PromptModule = OdinModule::default()
  assert_eq(m.name(), "odin")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[odin]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OdinModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-odin-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OdinModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .odin extension" {
  let path = "/tmp/moonship-test-odin-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.odin", "")
  let m = OdinModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Odin project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_odin_version: typical output" {
  assert_eq(parse_odin_version("odin version dev-2024-01"), "dev-2024-01")
}

///|
test "parse_odin_version: empty" {
  assert_eq(parse_odin_version(""), "")
}
