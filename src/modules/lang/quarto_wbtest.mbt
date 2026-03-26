///|
async test "name" {
  let m : &@ms.PromptModule = QuartoModule::default()
  assert_eq(m.name(), "quarto")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[quarto]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = QuartoModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-quarto-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = QuartoModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects _quarto.yml" {
  let path = "/tmp/moonship-test-quarto-yml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/_quarto.yml", "")
  let m = QuartoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Quarto project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .qmd extension" {
  let path = "/tmp/moonship-test-quarto-qmd"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/doc.qmd", "")
  let m = QuartoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Quarto project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
