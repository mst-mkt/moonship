///|
async test "name" {
  let m : &@ms.PromptModule = mojo_defaults()
  assert_eq(m.name(), "mojo")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[mojo]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, mojo_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-mojo-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = mojo_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .mojo extension" {
  let path = "/tmp/moonship-test-mojo-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.mojo", "")
  let m = mojo_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Mojo project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_mojo_version: typical output" {
  assert_eq(last_word("mojo 24.1.0"), "24.1.0")
}

///|
test "parse_mojo_version: empty" {
  assert_eq(last_word(""), "")
}
