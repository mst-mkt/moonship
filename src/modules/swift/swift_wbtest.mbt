///|
async test "name" {
  let m : &@ms.PromptModule = SwiftModule::new()
  assert_eq(m.name(), "swift")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[swift]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SwiftModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-swift-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = SwiftModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Package.swift" {
  let path = "/tmp/moonship-test-swift-package"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Package.swift", "")
  let m = SwiftModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Swift project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .swift extension" {
  let path = "/tmp/moonship-test-swift-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.swift", "")
  let m = SwiftModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Swift project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_swift_version: apple" {
  assert_eq(
    parse_swift_version(
      "Apple Swift version 5.2.2 (swiftlang-1103.0.32.6 clang-1103.0.32.51)",
    ),
    "5.2.2",
  )
}

///|
test "parse_swift_version: open source" {
  assert_eq(
    parse_swift_version(
      "Swift version 5.3-dev (LLVM 10.0.0, Clang 11.0.0, Swift 5.3-dev)",
    ),
    "5.3-dev",
  )
}

///|
test "parse_swift_version: empty" {
  assert_eq(parse_swift_version(""), "")
}

///|
test "parse_swift_version: no version keyword" {
  assert_eq(parse_swift_version("something else"), "")
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
