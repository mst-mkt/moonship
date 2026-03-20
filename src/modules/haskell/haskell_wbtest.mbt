///|
async test "name" {
  let m : &@ms.PromptModule = HaskellModule::new()
  assert_eq(m.name(), "haskell")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[haskell]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = HaskellModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-haskell-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = HaskellModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects stack.yaml" {
  let path = "/tmp/moonship-test-haskell-stack"
  setup_dir(path)
  @fs.write_string_to_file(path + "/stack.yaml", "")
  let m = HaskellModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects cabal.project" {
  let path = "/tmp/moonship-test-haskell-cabal"
  setup_dir(path)
  @fs.write_string_to_file(path + "/cabal.project", "")
  let m = HaskellModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .hs extension" {
  let path = "/tmp/moonship-test-haskell-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Main.hs", "")
  let m = HaskellModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .cabal extension" {
  let path = "/tmp/moonship-test-haskell-cabal-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/app.cabal", "")
  let m = HaskellModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
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
