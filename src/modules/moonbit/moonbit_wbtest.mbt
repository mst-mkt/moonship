///|
async test "name" {
  let m : &@ms.PromptModule = MoonbitModule::default()
  assert_eq(m.name(), "moonbit")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[moonbit]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = MoonbitModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-moonbit-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = MoonbitModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects moon.mod.json" {
  let path = "/tmp/moonship-test-moonbit-mod"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/moon.mod.json", "")
  let m = MoonbitModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects moon.pkg.json" {
  let path = "/tmp/moonship-test-moonbit-pkg"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/moon.pkg.json", "")
  let m = MoonbitModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .mbt extension" {
  let path = "/tmp/moonship-test-moonbit-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.mbt", "")
  let m = MoonbitModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: outputs version in moonbit project" {
  let path = "/tmp/moonship-test-moonbit-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/moon.mod.json", "")
  let m = MoonbitModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_true(result is Output(_))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_moon_version: standard" {
  assert_eq(
    parse_moon_version("moon 0.1.20260309 (f21b520 2026-03-09)"),
    "0.1.20260309",
  )
}

///|
test "parse_moon_version: simple" {
  assert_eq(parse_moon_version("moon 0.2.0"), "0.2.0")
}

///|
test "parse_moon_version: empty" {
  assert_eq(parse_moon_version(""), "")
}

///|
test "parse_moon_version: single word" {
  assert_eq(parse_moon_version("moon"), "")
}


