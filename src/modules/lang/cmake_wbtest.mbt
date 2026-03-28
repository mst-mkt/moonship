///|
async test "name" {
  let m : &@ms.PromptModule = cmake_defaults()
  assert_eq(m.name(), "cmake")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[cmake]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, cmake_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-cmake-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = cmake_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects CMakeLists.txt" {
  let path = "/tmp/moonship-test-cmake-lists"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/CMakeLists.txt", "")
  let m = cmake_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no CMake project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects CMakeCache.txt" {
  let path = "/tmp/moonship-test-cmake-cache"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/CMakeCache.txt", "")
  let m = cmake_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no CMake project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_cmake_version: standard" {
  assert_eq(parse_cmake_version("cmake version 3.27.4"), "3.27.4")
}

///|
test "parse_cmake_version: empty" {
  assert_eq(parse_cmake_version(""), "")
}

///|
test "parse_cmake_version: too few words" {
  assert_eq(parse_cmake_version("cmake version"), "")
}
