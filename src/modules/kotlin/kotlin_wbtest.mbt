///|
async test "name" {
  let m : &@ms.PromptModule = KotlinModule::new()
  assert_eq(m.name(), "kotlin")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[kotlin]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = KotlinModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-kotlin-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = KotlinModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .kt extension" {
  let path = "/tmp/moonship-test-kotlin-kt"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Main.kt", "")
  let m = KotlinModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Kotlin project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .kts extension" {
  let path = "/tmp/moonship-test-kotlin-kts"
  setup_dir(path)
  @fs.write_string_to_file(path + "/build.gradle.kts", "")
  let m = KotlinModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Kotlin project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_kotlin_version: runtime" {
  assert_eq(
    parse_kotlin_version("Kotlin version 1.4.21-release-411 (JRE 14.0.1+7)"),
    "1.4.21",
  )
}

///|
test "parse_kotlin_version: compiler" {
  assert_eq(
    parse_kotlin_version("info: kotlinc-jvm 1.4.21 (JRE 14.0.1+7)"),
    "1.4.21",
  )
}

///|
test "parse_kotlin_version: empty" {
  assert_eq(parse_kotlin_version(""), "")
}

///|
test "parse_kotlin_version: no version" {
  assert_eq(parse_kotlin_version("no version here"), "")
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
