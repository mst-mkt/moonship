///|
async test "name" {
  let m : &@ms.PromptModule = FortranModule::default()
  assert_eq(m.name(), "fortran")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[fortran]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = FortranModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-fortran-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = FortranModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects fpm.toml" {
  let path = "/tmp/moonship-test-fortran-fpm"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/fpm.toml", "")
  let m = FortranModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Fortran project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .f90 extension" {
  let path = "/tmp/moonship-test-fortran-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.f90", "")
  let m = FortranModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Fortran project detected"))
  @test_util.remove_dir_recursive(path)
}


