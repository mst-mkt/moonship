///|
test "first_line: single line" {
  assert_eq(first_line("hello"), "hello")
}

///|
test "first_line: multi line" {
  assert_eq(first_line("first\nsecond\n"), "first")
}

///|
test "first_line: empty" {
  assert_eq(first_line(""), "")
}

///|
test "first_line: trims carriage return" {
  assert_eq(first_line("v20.0.0\r\n"), "v20.0.0")
}

///|
test "strip_v_prefix: with v" {
  assert_eq(strip_v_prefix("v20.0.0"), "20.0.0")
}

///|
test "strip_v_prefix: without v" {
  assert_eq(strip_v_prefix("20.0.0"), "20.0.0")
}

///|
test "strip_v_prefix: empty" {
  assert_eq(strip_v_prefix(""), "")
}

///|
test "detect_project: file match" {
  let path = "/tmp/moonship-test-exec-detect-file"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Cargo.toml", "")

  assert_true(detect_project(path, ["Cargo.toml"], []))

  remove_dir_recursive(path)
}

///|
test "detect_project: extension match" {
  let path = "/tmp/moonship-test-exec-detect-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.rs", "")

  assert_true(detect_project(path, [], [".rs"]))

  remove_dir_recursive(path)
}

///|
test "detect_project: no match" {
  let path = "/tmp/moonship-test-exec-detect-empty"
  setup_dir(path)

  assert_false(detect_project(path, ["Cargo.toml"], [".rs"]))

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
