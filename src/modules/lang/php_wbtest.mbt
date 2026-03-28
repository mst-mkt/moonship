///|
async test "name" {
  let m : &@ms.PromptModule = php_defaults()
  assert_eq(m.name(), "php")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[php]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, php_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-php-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = php_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects composer.json" {
  let path = "/tmp/moonship-test-php-composer"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/composer.json", "")
  let m = php_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no PHP project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .php-version" {
  let path = "/tmp/moonship-test-php-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.php-version", "")
  let m = php_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no PHP project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .php extension" {
  let path = "/tmp/moonship-test-php-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/index.php", "")
  let m = php_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no PHP project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
