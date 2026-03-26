///|
async test "name" {
  let m : &@ms.PromptModule = CobolModule::default()
  assert_eq(m.name(), "cobol")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[cobol]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = CobolModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-cobol-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = CobolModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .cbl extension" {
  let path = "/tmp/moonship-test-cobol-cbl"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.cbl", "")
  let m = CobolModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no COBOL project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_cobol_version: typical output" {
  assert_eq(parse_cobol_version("cobc (GnuCOBOL) 3.1.2.0"), "3.1.2.0")
}

///|
test "parse_cobol_version: empty" {
  assert_eq(parse_cobol_version(""), "")
}

///|
test "parse_cobol_version: no version" {
  assert_eq(parse_cobol_version("no version here"), "")
}
