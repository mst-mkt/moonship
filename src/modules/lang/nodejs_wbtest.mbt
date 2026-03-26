///|
async test "name" {
  let m : &@ms.PromptModule = NodejsModule::default()
  assert_eq(m.name(), "nodejs")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[nodejs]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = NodejsModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-nodejs-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = NodejsModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects package.json" {
  let path = "/tmp/moonship-test-nodejs-pkg"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{}")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .node-version file" {
  let path = "/tmp/moonship-test-nodejs-nodever"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.node-version", "20.0.0")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .js extension" {
  let path = "/tmp/moonship-test-nodejs-jsext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/index.js", "")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}
