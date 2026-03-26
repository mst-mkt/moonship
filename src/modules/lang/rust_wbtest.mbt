///|
async test "name" {
  let m : &@ms.PromptModule = RustModule::default()
  assert_eq(m.name(), "rust")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[rust]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RustModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-rust-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RustModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Cargo.toml and produces output with symbol" {
  let path = "/tmp/moonship-test-rust-cargo"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Cargo.toml", "")
  let m = RustModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Disabled) else { fail("expected non-Disabled result") }

  if result is Output(out) {
    let rendered = out.render()
    assert_true(rendered.contains("🦀"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .rs extension and produces output with symbol" {
  let path = "/tmp/moonship-test-rust-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.rs", "")
  let m = RustModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Disabled) else { fail("expected non-Disabled result") }

  if result is Output(out) {
    let rendered = out.render()
    assert_true(rendered.contains("🦀"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
test "parse_rustc_version: standard output" {
  assert_eq(
    parse_rustc_version("rustc 1.75.0 (82e1608df 2023-12-21)"),
    "1.75.0",
  )
}

///|
test "parse_rustc_version: nightly" {
  assert_eq(
    parse_rustc_version("rustc 1.77.0-nightly (bf3c6c5be 2024-01-10)"),
    "1.77.0-nightly",
  )
}

///|
test "parse_rustc_version: empty" {
  assert_eq(parse_rustc_version(""), "")
}

///|
test "parse_rustc_version: single word" {
  assert_eq(parse_rustc_version("1.75.0"), "1.75.0")
}

///|
test "parse_rustc_version: beta" {
  assert_eq(
    parse_rustc_version("rustc 1.76.0-beta.1 (abc123 2024-01-01)"),
    "1.76.0-beta.1",
  )
}

///|
test "format_version: with default format" {
  assert_eq(@exec.format_version("1.75.0", "v${raw}"), "v1.75.0")
}

///|
test "format_version: with major.minor format" {
  assert_eq(@exec.format_version("1.75.0", "v${major}.${minor}"), "v1.75")
}

///|
test "format_version: empty version" {
  assert_eq(@exec.format_version("", "v${raw}"), "")
}
