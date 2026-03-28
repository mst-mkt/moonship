///|
async test "name" {
  let m : &@ms.PromptModule = fennel_defaults()
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
  let m = SimpleLangModule::from_config(config, fennel_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: detects .fnl extension" {
  let path = "/tmp/moonship-test-fennel-fnl"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/init.fnl", "")
  let m = fennel_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Fennel project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
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
