///|
async test "name" {
  let m : &@ms.PromptModule = CppModule::new()
  assert_eq(m.name(), "cpp")
}

///|
async test "execute: disabled by default returns Disabled" {
  let m = CppModule::new()
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
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path, config~)
  let m = CppModule::from_config(config)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
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
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.cpp", "")
  let m = CppModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C++ project detected"))
  remove_dir_recursive(path)
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
  setup_dir(path)
  @fs.write_string_to_file(path + "/lib.hpp", "")
  let m = CppModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no C++ project detected"))
  remove_dir_recursive(path)
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
