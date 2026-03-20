///|
async test "name" {
  let m : &@ms.PromptModule = OdinModule::new()
  assert_eq(m.name(), "odin")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[odin]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OdinModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-odin-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OdinModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .odin extension" {
  let path = "/tmp/moonship-test-odin-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.odin", "")
  let m = OdinModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Odin project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_odin_version: typical output" {
  assert_eq(parse_odin_version("odin version dev-2024-01"), "dev-2024-01")
}

///|
test "parse_odin_version: empty" {
  assert_eq(parse_odin_version(""), "")
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
