///|
async test "name" {
  let m : &@ms.PromptModule = elm_defaults()
  assert_eq(m.name(), "elm")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[elm]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, elm_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-elm-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = elm_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects elm.json" {
  let path = "/tmp/moonship-test-elm-json"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/elm.json", "")
  let m = elm_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Elm project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .elm-version" {
  let path = "/tmp/moonship-test-elm-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.elm-version", "")
  let m = elm_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Elm project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .elm extension" {
  let path = "/tmp/moonship-test-elm-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.elm", "")
  let m = elm_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Elm project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
