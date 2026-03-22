///|
async test "name" {
  let m : &@ms.PromptModule = DartModule::default()
  assert_eq(m.name(), "dart")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[dart]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = DartModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-dart-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = DartModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects pubspec.yaml" {
  let path = "/tmp/moonship-test-dart-pubspec"
  setup_dir(path)
  @fs.write_string_to_file(path + "/pubspec.yaml", "")
  let m = DartModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Dart project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects pubspec.yml" {
  let path = "/tmp/moonship-test-dart-yml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/pubspec.yml", "")
  let m = DartModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Dart project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects pubspec.lock" {
  let path = "/tmp/moonship-test-dart-lock"
  setup_dir(path)
  @fs.write_string_to_file(path + "/pubspec.lock", "")
  let m = DartModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Dart project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .dart extension" {
  let path = "/tmp/moonship-test-dart-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.dart", "")
  let m = DartModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Dart project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_dart_version: vm format" {
  assert_eq(
    parse_dart_version(
      "Dart VM version: 2.8.4 (stable) (Wed Jun 3 12:26:04 2020 +0200) on \"linux_x64\"",
    ),
    "2.8.4",
  )
}

///|
test "parse_dart_version: sdk format" {
  assert_eq(
    parse_dart_version(
      "Dart SDK version: 2.15.1 (stable) (Tue Dec 14 13:32:21 2021 +0100) on \"linux_x64\"",
    ),
    "2.15.1",
  )
}

///|
test "parse_dart_version: dart 3" {
  assert_eq(
    parse_dart_version("Dart SDK version: 3.2.0 (stable) on \"linux_x64\""),
    "3.2.0",
  )
}

///|
test "parse_dart_version: empty" {
  assert_eq(parse_dart_version(""), "")
}

///|
test "parse_dart_version: too few words" {
  assert_eq(parse_dart_version("Dart VM version:"), "")
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
