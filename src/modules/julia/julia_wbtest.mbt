///|
async test "name" {
  let m : &@ms.PromptModule = JuliaModule::default()
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
  let m = JuliaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-julia-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = JuliaModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Project.toml" {
  let path = "/tmp/moonship-test-julia-project"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Project.toml", "")
  let m = JuliaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Manifest.toml" {
  let path = "/tmp/moonship-test-julia-manifest"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Manifest.toml", "")
  let m = JuliaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .jl extension" {
  let path = "/tmp/moonship-test-julia-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.jl", "")
  let m = JuliaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_julia_version: standard" {
  assert_eq(parse_julia_version("julia version 1.8.5"), "1.8.5")
}

///|
test "parse_julia_version: rc" {
  assert_eq(parse_julia_version("julia version 1.9.0-rc1"), "1.9.0-rc1")
}

///|
test "parse_julia_version: empty" {
  assert_eq(parse_julia_version(""), "")
}

///|
test "parse_julia_version: too few words" {
  assert_eq(parse_julia_version("julia version"), "")
}
