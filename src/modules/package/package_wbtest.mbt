///|
async test "name" {
  let m : &@ms.PromptModule = PackageModule::default()
  assert_eq(m.name(), "package")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[package]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PackageModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no package file returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = PackageModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "detect_version: package.json" {
  let path = "/tmp/moonship-test-package-json"
  setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"3.0.0\"}")

  assert_eq(detect_version(path), "3.0.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: Cargo.toml" {
  let path = "/tmp/moonship-test-package-cargo"
  setup_dir(path)
  @fs.write_string_to_file(
    path + "/Cargo.toml",
    "[package]\nversion = \"0.5.0\"",
  )

  assert_eq(detect_version(path), "0.5.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: pubspec.yaml" {
  let path = "/tmp/moonship-test-package-pubspec"
  setup_dir(path)
  @fs.write_string_to_file(
    path + "/pubspec.yaml",
    "name: myapp\nversion: 1.2.3\n",
  )

  assert_eq(detect_version(path), "1.2.3")

  remove_dir_recursive(path)
}

///|
async test "detect_version: pom.xml" {
  let path = "/tmp/moonship-test-package-pom"
  setup_dir(path)
  @fs.write_string_to_file(
    path + "/pom.xml",
    "<project><version>4.0.0</version></project>",
  )

  assert_eq(detect_version(path), "4.0.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: jsr.json" {
  let path = "/tmp/moonship-test-package-jsr"
  setup_dir(path)
  @fs.write_string_to_file(path + "/jsr.json", "{\"version\": \"0.9.0\"}")

  assert_eq(detect_version(path), "0.9.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: daml.yaml" {
  let path = "/tmp/moonship-test-package-daml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/daml.yaml", "version: 1.5.0\n")

  assert_eq(detect_version(path), "1.5.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: DESCRIPTION (R)" {
  let path = "/tmp/moonship-test-package-r"
  setup_dir(path)
  @fs.write_string_to_file(
    path + "/DESCRIPTION",
    "Package: mypkg\nVersion: 0.8.0\n",
  )

  assert_eq(detect_version(path), "0.8.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: nimble" {
  let path = "/tmp/moonship-test-package-nimble"
  setup_dir(path)
  @fs.write_string_to_file(path + "/myproject.nimble", "version = \"0.2.0\"\n")

  assert_eq(detect_version(path), "0.2.0")

  remove_dir_recursive(path)
}

///|
async test "detect_version: no package file" {
  let path = "/tmp/moonship-test-package-empty"
  setup_dir(path)

  assert_eq(detect_version(path), "")

  remove_dir_recursive(path)
}

///|
async test "detect_version: priority order" {
  let path = "/tmp/moonship-test-package-priority"
  setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"1.0.0\"}")
  @fs.write_string_to_file(
    path + "/Cargo.toml",
    "[package]\nversion = \"2.0.0\"",
  )

  assert_eq(detect_version(path), "1.0.0")

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

// --- display_private ---

///|
test "is_private_package: private true" {
  let path = "/tmp/moonship-test-pkg-private"
  @fs.create_dir(path) catch { _ => () }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  assert_true(is_private_package(path))

  @fs.remove_file(path + "/package.json") catch { _ => () }
  @fs.remove_dir(path) catch { _ => () }
}

///|
test "is_private_package: not private" {
  let path = "/tmp/moonship-test-pkg-public"
  @fs.create_dir(path) catch { _ => () }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\"}",
  )

  assert_false(is_private_package(path))

  @fs.remove_file(path + "/package.json") catch { _ => () }
  @fs.remove_dir(path) catch { _ => () }
}

///|
test "is_private_package: no package.json" {
  assert_false(is_private_package("/tmp"))
}

///|
async test "execute: private package skipped by default" {
  let path = "/tmp/moonship-test-pkg-skip-private"
  @fs.create_dir(path) catch { _ => () }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  let m = PackageModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Skipped(_))

  @fs.remove_file(path + "/package.json") catch { _ => () }
  @fs.remove_dir(path) catch { _ => () }
}

///|
async test "execute: private package shown when display_private=true" {
  let path = "/tmp/moonship-test-pkg-show-private"
  @fs.create_dir(path) catch { _ => () }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  let config = @config.Config::from_toml(
    (
      #|[package]
      #|display_private = true
    ),
  )
  let m = PackageModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)

  guard m.execute(ctx) is Output(out) else {
    @fs.remove_file(path + "/package.json") catch { _ => () }
    @fs.remove_dir(path) catch { _ => () }
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("1.0.0"))

  @fs.remove_file(path + "/package.json") catch { _ => () }
  @fs.remove_dir(path) catch { _ => () }
}
