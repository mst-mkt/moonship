///|
async test "name" {
  let m : &@ms.PromptModule = MoonbitModule::new()
  assert_eq(m.name(), "moonbit")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[moonbit]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = MoonbitModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-moonbit-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = MoonbitModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects moon.mod.json" {
  let path = "/tmp/moonship-test-moonbit-mod"
  setup_dir(path)
  @fs.write_string_to_file(path + "/moon.mod.json", "")
  let m = MoonbitModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects moon.pkg.json" {
  let path = "/tmp/moonship-test-moonbit-pkg"
  setup_dir(path)
  @fs.write_string_to_file(path + "/moon.pkg.json", "")
  let m = MoonbitModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .mbt extension" {
  let path = "/tmp/moonship-test-moonbit-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.mbt", "")
  let m = MoonbitModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no MoonBit project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: outputs version in moonbit project" {
  let path = "/tmp/moonship-test-moonbit-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/moon.mod.json", "")
  let m = MoonbitModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_true(result is Output(_))
  remove_dir_recursive(path)
}

///|
test "parse_moon_version: standard" {
  assert_eq(
    parse_moon_version("moon 0.1.20260309 (f21b520 2026-03-09)"),
    "0.1.20260309",
  )
}

///|
test "parse_moon_version: simple" {
  assert_eq(parse_moon_version("moon 0.2.0"), "0.2.0")
}

///|
test "parse_moon_version: empty" {
  assert_eq(parse_moon_version(""), "")
}

///|
test "parse_moon_version: single word" {
  assert_eq(parse_moon_version("moon"), "")
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
