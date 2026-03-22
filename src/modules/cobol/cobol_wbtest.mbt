///|
async test "name" {
  let m : &@ms.PromptModule = CobolModule::default()
  assert_eq(m.name(), "cobol")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[cobol]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = CobolModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-cobol-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = CobolModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .cbl extension" {
  let path = "/tmp/moonship-test-cobol-cbl"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.cbl", "")
  let m = CobolModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no COBOL project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_cobol_version: typical output" {
  assert_eq(parse_cobol_version("cobc (GnuCOBOL) 3.1.2.0"), "3.1.2.0")
}

///|
test "parse_cobol_version: empty" {
  assert_eq(parse_cobol_version(""), "")
}

///|
test "parse_cobol_version: no version" {
  assert_eq(parse_cobol_version("no version here"), "")
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
