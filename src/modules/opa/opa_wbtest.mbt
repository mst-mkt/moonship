///|
async test "name" {
  let m : &@ms.PromptModule = OpaModule::new()
  assert_eq(m.name(), "opa")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[opa]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OpaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-opa-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OpaModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .rego extension" {
  let path = "/tmp/moonship-test-opa-rego"
  setup_dir(path)
  @fs.write_string_to_file(path + "/policy.rego", "")
  let m = OpaModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OPA project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_opa_version: typical output" {
  assert_eq(
    parse_opa_version("Version: 0.55.0\nBuild Commit: abc123"),
    "0.55.0",
  )
}

///|
test "parse_opa_version: single line" {
  assert_eq(parse_opa_version("Version: 0.55.0"), "0.55.0")
}

///|
test "parse_opa_version: empty" {
  assert_eq(parse_opa_version(""), "")
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
