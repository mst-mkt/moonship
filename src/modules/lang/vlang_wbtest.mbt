///|
async test "name" {
  let m : &@ms.PromptModule = vlang_defaults()
  assert_eq(m.name(), "vlang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[vlang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, vlang_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-vlang-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = vlang_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects v.mod" {
  let path = "/tmp/moonship-test-vlang-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/v.mod", "")
  let m = vlang_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no V project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .v extension" {
  let path = "/tmp/moonship-test-vlang-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.v", "")
  let m = vlang_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no V project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
