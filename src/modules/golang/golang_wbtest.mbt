///|
async test "name" {
  let m : &@ms.PromptModule = GolangModule::default()
  assert_eq(m.name(), "golang")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[golang]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GolangModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-golang-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = GolangModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects go.mod" {
  let path = "/tmp/moonship-test-golang-gomod"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/go.mod", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects go.sum" {
  let path = "/tmp/moonship-test-golang-gosum"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/go.sum", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects go.work" {
  let path = "/tmp/moonship-test-golang-gowork"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/go.work", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .go extension" {
  let path = "/tmp/moonship-test-golang-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.go", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Gopkg.yml" {
  let path = "/tmp/moonship-test-golang-gopkg"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Gopkg.yml", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .go-version" {
  let path = "/tmp/moonship-test-golang-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.go-version", "")
  let m = GolangModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(not(m.execute(ctx) is Disabled))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_go_version: standard output" {
  assert_eq(parse_go_version("go version go1.21.5 linux/amd64"), "1.21.5")
}

///|
test "parse_go_version: darwin" {
  assert_eq(parse_go_version("go version go1.22.0 darwin/arm64"), "1.22.0")
}

///|
test "parse_go_version: empty" {
  assert_eq(parse_go_version(""), "")
}

///|
test "parse_go_version: unexpected format" {
  assert_eq(parse_go_version("something else"), "something else")
}
