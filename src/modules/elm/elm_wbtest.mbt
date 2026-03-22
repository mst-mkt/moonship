///|
async test "name" {
  let m : &@ms.PromptModule = ElmModule::default()
  assert_eq(m.name(), "elm")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[elm]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ElmModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-elm-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ElmModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects elm.json" {
  let path = "/tmp/moonship-test-elm-json"
  setup_dir(path)
  @fs.write_string_to_file(path + "/elm.json", "")
  let m = ElmModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Elm project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .elm-version" {
  let path = "/tmp/moonship-test-elm-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.elm-version", "")
  let m = ElmModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Elm project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .elm extension" {
  let path = "/tmp/moonship-test-elm-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Main.elm", "")
  let m = ElmModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Elm project detected"))
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
