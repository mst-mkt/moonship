///|
async test "name" {
  let m : &@ms.PromptModule = FennelModule::default()
  assert_eq(m.name(), "fennel")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[fennel]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = FennelModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: detects .fnl extension" {
  let path = "/tmp/moonship-test-fennel-fnl"
  setup_dir(path)
  @fs.write_string_to_file(path + "/init.fnl", "")
  let m = FennelModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Fennel project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_fennel_version: typical output" {
  assert_eq(parse_fennel_version("Fennel 1.3.1"), "1.3.1")
}

///|
test "parse_fennel_version: empty" {
  assert_eq(parse_fennel_version(""), "")
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
