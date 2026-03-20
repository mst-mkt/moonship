///|
async test "name" {
  let m : &@ms.PromptModule = MojoModule::new()
  assert_eq(m.name(), "mojo")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[mojo]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = MojoModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-mojo-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = MojoModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .mojo extension" {
  let path = "/tmp/moonship-test-mojo-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.mojo", "")
  let m = MojoModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Mojo project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_mojo_version: typical output" {
  assert_eq(parse_mojo_version("mojo 24.1.0"), "24.1.0")
}

///|
test "parse_mojo_version: empty" {
  assert_eq(parse_mojo_version(""), "")
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
