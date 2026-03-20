///|
async test "name" {
  let m : &@ms.PromptModule = GleamModule::new()
  assert_eq(m.name(), "gleam")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[gleam]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GleamModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-gleam-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = GleamModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects gleam.toml" {
  let path = "/tmp/moonship-test-gleam-toml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/gleam.toml", "")
  let m = GleamModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Gleam project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .gleam extension" {
  let path = "/tmp/moonship-test-gleam-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.gleam", "")
  let m = GleamModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Gleam project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_gleam_version: standard" {
  assert_eq(parse_gleam_version("gleam 1.0.0"), "1.0.0")
}

///|
test "parse_gleam_version: with extra info" {
  assert_eq(parse_gleam_version("gleam 0.33.0-rc1"), "0.33.0-rc1")
}

///|
test "parse_gleam_version: empty" {
  assert_eq(parse_gleam_version(""), "")
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
