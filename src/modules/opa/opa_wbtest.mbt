///|
async test "name" {
  let m : &@ms.PromptModule = OpaModule::default()
  assert_eq(m.name(), "opa")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[opa]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OpaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-opa-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OpaModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .rego extension" {
  let path = "/tmp/moonship-test-opa-rego"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/policy.rego", "")
  let m = OpaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OPA project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_opa_version: typical output" {
  assert_eq(
    parse_opa_version("Version: 0.55.0\nBuild Commit: abc123"),
    "0.55.0",
  )
}

///|
test "parse_opa_version: single line" {
  assert_eq(parse_opa_version("Version: 0.55.0"), "0.55.0")
}

///|
test "parse_opa_version: empty" {
  assert_eq(parse_opa_version(""), "")
}
