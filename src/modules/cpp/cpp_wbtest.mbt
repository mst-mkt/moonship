///|
async test "name" {
  let m : &@ms.PromptModule = CppModule::default()
  assert_eq(m.name(), "cpp")
}

///|
async test "execute: disabled by default returns Disabled" {
  let m = CppModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled no project returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[cpp]
      #|disabled = false
    ),
  )
  let path = "/tmp/moonship-test-cpp-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path, config~)
  let m = CppModule::from_config(config)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .cpp extension" {
  let config = @config.Config::from_toml(
    (
      #|[cpp]
      #|disabled = false
    ),
  )
  let path = "/tmp/moonship-test-cpp-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.cpp", "")
  let m = CppModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C++ project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .hpp extension" {
  let config = @config.Config::from_toml(
    (
      #|[cpp]
      #|disabled = false
    ),
  )
  let path = "/tmp/moonship-test-cpp-hpp"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/lib.hpp", "")
  let m = CppModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C++ project detected"))
  @test_util.remove_dir_recursive(path)
}


