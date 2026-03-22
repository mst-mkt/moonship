///|
async test "name" {
  let m : &@ms.PromptModule = MiseModule::default()
  assert_eq(m.name(), "mise")
}

///|
async test "execute: disabled by default" {
  let m = MiseModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no mise files returns Skipped" {
  let path = "/tmp/moonship-test-mise-empty"
  setup_dir(path)
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects mise.toml" {
  let path = "/tmp/moonship-test-mise-toml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/mise.toml", "")
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no mise project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .mise.toml" {
  let path = "/tmp/moonship-test-mise-dottoml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.mise.toml", "")
  let config = @config.Config::from_toml(
    (
      #|[mise]
      #|disabled = false
    ),
  )
  let m = MiseModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no mise project detected"))
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
