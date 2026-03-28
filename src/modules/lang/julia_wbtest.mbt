///|
async test "name" {
  let m : &@ms.PromptModule = julia_defaults()
  assert_eq(m.name(), "julia")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[julia]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, julia_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-julia-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = julia_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Project.toml" {
  let path = "/tmp/moonship-test-julia-project"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Project.toml", "")
  let m = julia_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Julia project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Manifest.toml" {
  let path = "/tmp/moonship-test-julia-manifest"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Manifest.toml", "")
  let m = julia_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Julia project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .jl extension" {
  let path = "/tmp/moonship-test-julia-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.jl", "")
  let m = julia_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Julia project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_julia_version: standard" {
  assert_eq(nth_word("julia version 1.8.5", 2), "1.8.5")
}

///|
test "parse_julia_version: rc" {
  assert_eq(nth_word("julia version 1.9.0-rc1", 2), "1.9.0-rc1")
}

///|
test "parse_julia_version: empty" {
  assert_eq(nth_word("", 2), "")
}

///|
test "parse_julia_version: too few words" {
  assert_eq(nth_word("julia version", 2), "")
}
