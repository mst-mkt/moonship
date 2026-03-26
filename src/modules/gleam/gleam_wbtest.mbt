///|
async test "name" {
  let m : &@ms.PromptModule = GleamModule::default()
  assert_eq(m.name(), "gleam")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[gleam]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GleamModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-gleam-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = GleamModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects gleam.toml" {
  let path = "/tmp/moonship-test-gleam-toml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/gleam.toml", "")
  let m = GleamModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Gleam project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .gleam extension" {
  let path = "/tmp/moonship-test-gleam-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.gleam", "")
  let m = GleamModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Gleam project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_gleam_version: standard" {
  assert_eq(parse_gleam_version("gleam 1.0.0"), "1.0.0")
}

///|
test "parse_gleam_version: with extra info" {
  assert_eq(parse_gleam_version("gleam 0.33.0-rc1"), "0.33.0-rc1")
}

///|
test "parse_gleam_version: empty" {
  assert_eq(parse_gleam_version(""), "")
}


