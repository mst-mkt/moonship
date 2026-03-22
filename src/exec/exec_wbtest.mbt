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
test "find_semver: gcc output" {
  assert_eq(find_semver("gcc (GCC) 13.2.1 20230801"), "13.2.1")
}

///|
test "find_semver: clang output" {
  assert_eq(find_semver("clang version 16.0.6"), "16.0.6")
}

///|
test "find_semver: with hyphen suffix" {
  assert_eq(find_semver("clang version 16.0.6-1"), "16.0.6")
}

///|
test "find_semver: empty" {
  assert_eq(find_semver(""), "")
}

///|
test "find_semver: trailing dot" {
  assert_eq(find_semver("version 1.2.3."), "1.2.3")
}

///|
test "find_semver: no semver" {
  assert_eq(find_semver("no version here"), "")
}

///|
test "detect_compiler_name: clang" {
  assert_eq(
    detect_compiler_name("clang version 16.0.6", [
      ("clang", "clang"),
      ("gcc", "Free Software Foundation"),
    ]),
    "clang",
  )
}

///|
test "detect_compiler_name: gcc" {
  assert_eq(
    detect_compiler_name(
      "gcc (GCC) 13.2.1 Copyright (C) Free Software Foundation",
      [("clang", "clang"), ("gcc", "Free Software Foundation")],
    ),
    "gcc",
  )
}

///|
test "detect_compiler_name: unknown" {
  assert_eq(
    detect_compiler_name("some unknown compiler", [
      ("clang", "clang"),
      ("gcc", "Free Software Foundation"),
    ]),
    "",
  )
}

///|
fn setup_dir(path : String) -> Unit {
  remove_dir_recursive(path)
  @fs.create_dir(path) catch {
    _ => ()
  }
}

///|
test "extract_semver: basic" {
  assert_eq(extract_semver("1.2.3"), "1.2.3")
}

///|
test "extract_semver: with trailing non-digit" {
  assert_eq(extract_semver("1.2.3-beta"), "1.2.3")
}

///|
test "extract_semver: leading text" {
  assert_eq(extract_semver("abc"), "")
}

///|
test "extract_semver: only two parts" {
  assert_eq(extract_semver("1.2"), "")
}

///|
test "extract_semver: trailing dot" {
  assert_eq(extract_semver("1.2.3."), "1.2.3")
}

///|
test "extract_semver: empty string" {
  assert_eq(extract_semver(""), "")
}

///|
test "extract_semver: single number" {
  assert_eq(extract_semver("5"), "")
}

///|
test "extract_semver: many dots" {
  assert_eq(extract_semver("1.2.3.4"), "1.2.3.4")
}

///|
test "find_semver: v prefix not matched" {
  assert_eq(find_semver("v1.2.3"), "")
}

///|
test "find_semver: version keyword with semver" {
  assert_eq(find_semver("version 1.2.3"), "1.2.3")
}

///|
test "find_semver: no version" {
  assert_eq(find_semver("no version here"), "")
}

///|
test "find_semver: multiple candidates picks first semver" {
  assert_eq(find_semver("v1 2.3.4 extra"), "2.3.4")
}

///|
test "detect_compiler_name: empty output" {
  assert_eq(detect_compiler_name("", [("gcc", "GCC")]), "")
}

///|
test "detect_compiler_name: empty compilers" {
  assert_eq(detect_compiler_name("some output", []), "")
}

///|
test "add_v_prefix: already has v" {
  assert_eq(add_v_prefix("v1.0"), "v1.0")
}

///|
test "add_v_prefix: already has V" {
  assert_eq(add_v_prefix("V1.0"), "V1.0")
}

///|
test "add_v_prefix: empty" {
  assert_eq(add_v_prefix(""), "")
}

///|
test "add_v_prefix: normal" {
  assert_eq(add_v_prefix("1.0"), "v1.0")
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
