///|
async test "name" {
  let m : &@ms.PromptModule = crystal_defaults()
  assert_eq(m.name(), "crystal")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[crystal]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, crystal_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-crystal-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = crystal_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects shard.yml" {
  let path = "/tmp/moonship-test-crystal-shard"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/shard.yml", "")
  let m = crystal_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Crystal project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .cr extension" {
  let path = "/tmp/moonship-test-crystal-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.cr", "")
  let m = crystal_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Crystal project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_crystal_version: standard" {
  assert_eq(parse_crystal_version("Crystal 1.7.3 (2023-03-20)"), "1.7.3")
}

///|
test "parse_crystal_version: with build info" {
  assert_eq(
    parse_crystal_version("Crystal 1.10.0 [dd40a27] (2023-10-09)"),
    "1.10.0",
  )
}

///|
test "parse_crystal_version: empty" {
  assert_eq(parse_crystal_version(""), "")
}

///|
test "parse_crystal_version: single word" {
  assert_eq(parse_crystal_version("Crystal"), "")
}
