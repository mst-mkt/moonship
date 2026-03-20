///|
async test "name" {
  let m : &@ms.PromptModule = RlangModule::new()
  assert_eq(m.name(), "rlang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[rlang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RlangModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-rlang-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RlangModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects DESCRIPTION" {
  let path = "/tmp/moonship-test-rlang-file"
  setup_dir(path)
  @fs.write_string_to_file(path + "/DESCRIPTION", "")
  let m = RlangModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no R project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .R extension" {
  let path = "/tmp/moonship-test-rlang-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.R", "")
  let m = RlangModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no R project detected"))
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
