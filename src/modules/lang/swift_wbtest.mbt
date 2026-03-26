///|
async test "name" {
  let m : &@ms.PromptModule = SwiftModule::default()
  assert_eq(m.name(), "swift")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[swift]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SwiftModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-swift-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = SwiftModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Package.swift" {
  let path = "/tmp/moonship-test-swift-package"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Package.swift", "")
  let m = SwiftModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Swift project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("🐦"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .swift extension" {
  let path = "/tmp/moonship-test-swift-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.swift", "")
  let m = SwiftModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Swift project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("🐦"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_swift_version: apple" {
  assert_eq(
    parse_swift_version(
      "Apple Swift version 5.2.2 (swiftlang-1103.0.32.6 clang-1103.0.32.51)",
    ),
    "5.2.2",
  )
}

///|
test "parse_swift_version: open source" {
  assert_eq(
    parse_swift_version(
      "Swift version 5.3-dev (LLVM 10.0.0, Clang 11.0.0, Swift 5.3-dev)",
    ),
    "5.3-dev",
  )
}

///|
test "parse_swift_version: empty" {
  assert_eq(parse_swift_version(""), "")
}

///|
test "parse_swift_version: no version keyword" {
  assert_eq(parse_swift_version("something else"), "")
}
