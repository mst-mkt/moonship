///|
async test "name" {
  let m : &@ms.PromptModule = nim_defaults()
  assert_eq(m.name(), "nim")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[nim]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, nim_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-nim-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = nim_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects nim.cfg" {
  let path = "/tmp/moonship-test-nim-cfg"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/nim.cfg", "")
  let m = nim_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Nim project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .nim extension" {
  let path = "/tmp/moonship-test-nim-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.nim", "")
  let m = nim_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Nim project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .nims extension" {
  let path = "/tmp/moonship-test-nim-nims"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/config.nims", "")
  let m = nim_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Nim project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .nimble extension" {
  let path = "/tmp/moonship-test-nim-nimble"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.nimble", "")
  let m = nim_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Nim project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_nim_version: standard" {
  assert_eq(
    parse_nim_version("Nim Compiler Version 1.6.10 [Linux: amd64]"),
    "1.6.10",
  )
}

///|
test "parse_nim_version: version 2" {
  assert_eq(
    parse_nim_version("Nim Compiler Version 2.0.0 [Linux: amd64]"),
    "2.0.0",
  )
}

///|
test "parse_nim_version: empty" {
  assert_eq(parse_nim_version(""), "")
}

///|
test "parse_nim_version: no version number" {
  assert_eq(parse_nim_version("Nim Compiler Version"), "")
}
