///|
async test "name" {
  let m : &@ms.PromptModule = CrystalModule::default()
  assert_eq(m.name(), "crystal")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[crystal]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = CrystalModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-crystal-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = CrystalModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects shard.yml" {
  let path = "/tmp/moonship-test-crystal-shard"
  setup_dir(path)
  @fs.write_string_to_file(path + "/shard.yml", "")
  let m = CrystalModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Crystal project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .cr extension" {
  let path = "/tmp/moonship-test-crystal-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.cr", "")
  let m = CrystalModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Crystal project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_crystal_version: standard" {
  assert_eq(parse_crystal_version("Crystal 1.7.3 (2023-03-20)"), "1.7.3")
}

///|
test "parse_crystal_version: with build info" {
  assert_eq(
    parse_crystal_version("Crystal 1.10.0 [dd40a27] (2023-10-09)"),
    "1.10.0",
  )
}

///|
test "parse_crystal_version: empty" {
  assert_eq(parse_crystal_version(""), "")
}

///|
test "parse_crystal_version: single word" {
  assert_eq(parse_crystal_version("Crystal"), "")
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
