///|
async test "name" {
  let m : &@ms.PromptModule = TypstModule::default()
  assert_eq(m.name(), "typst")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[typst]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = TypstModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-typst-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = TypstModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects template.typ" {
  let path = "/tmp/moonship-test-typst-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/template.typ", "")
  let m = TypstModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Typst project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .typ extension" {
  let path = "/tmp/moonship-test-typst-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.typ", "")
  let m = TypstModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Typst project detected"))
  @test_util.remove_dir_recursive(path)
}
