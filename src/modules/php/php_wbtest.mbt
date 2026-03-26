///|
async test "name" {
  let m : &@ms.PromptModule = PhpModule::default()
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
  let m = PhpModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-php-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PhpModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects composer.json" {
  let path = "/tmp/moonship-test-php-composer"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/composer.json", "")
  let m = PhpModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no PHP project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .php-version" {
  let path = "/tmp/moonship-test-php-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.php-version", "")
  let m = PhpModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no PHP project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .php extension" {
  let path = "/tmp/moonship-test-php-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/index.php", "")
  let m = PhpModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no PHP project detected"))
  @test_util.remove_dir_recursive(path)
}


