///|
async test "name" {
  let m : &@ms.PromptModule = CMakeModule::new()
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
  let m = CMakeModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-cmake-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = CMakeModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects CMakeLists.txt" {
  let path = "/tmp/moonship-test-cmake-lists"
  setup_dir(path)
  @fs.write_string_to_file(path + "/CMakeLists.txt", "")
  let m = CMakeModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no CMake project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects CMakeCache.txt" {
  let path = "/tmp/moonship-test-cmake-cache"
  setup_dir(path)
  @fs.write_string_to_file(path + "/CMakeCache.txt", "")
  let m = CMakeModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no CMake project detected"))
  remove_dir_recursive(path)
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

///|
fn setup_dir(path : String) -> Unit {
  remove_dir_recursive(path)
  @fs.create_dir(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_recursive(path : String) -> Unit {
  if not(@fs.path_exists(path)) {
    return
  }

  let entries = @fs.read_dir(path) catch { _ => return }

  for entry in entries {
    let full = path + "/" + entry
    let is_dir = @fs.is_dir(full) catch { _ => false }

    if is_dir {
      remove_dir_recursive(full)
    } else {
      @fs.remove_file(full) catch {
        _ => ()
      }
    }
  }

  @fs.remove_dir(path) catch {
    _ => ()
  }
}
