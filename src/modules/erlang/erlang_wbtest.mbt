///|
async test "name" {
  let m : &@ms.PromptModule = ErlangModule::new()
  assert_eq(m.name(), "erlang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[erlang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ErlangModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-erlang-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ErlangModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects rebar.config" {
  let path = "/tmp/moonship-test-erlang-rebar"
  setup_dir(path)
  @fs.write_string_to_file(path + "/rebar.config", "")
  let m = ErlangModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Erlang project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects erlang.mk" {
  let path = "/tmp/moonship-test-erlang-mk"
  setup_dir(path)
  @fs.write_string_to_file(path + "/erlang.mk", "")
  let m = ErlangModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Erlang project detected"))
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
