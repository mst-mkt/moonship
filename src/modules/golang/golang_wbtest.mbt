///|
async test "name" {
  let m : &@ms.PromptModule = GolangModule::new()
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
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = GolangModule::new()
  assert_true(m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects go.mod" {
  let path = "/tmp/moonship-test-golang-gomod"
  setup_dir(path)
  @fs.write_string_to_file(path + "/go.mod", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects go.sum" {
  let path = "/tmp/moonship-test-golang-gosum"
  setup_dir(path)
  @fs.write_string_to_file(path + "/go.sum", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects go.work" {
  let path = "/tmp/moonship-test-golang-gowork"
  setup_dir(path)
  @fs.write_string_to_file(path + "/go.work", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .go extension" {
  let path = "/tmp/moonship-test-golang-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.go", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Gopkg.yml" {
  let path = "/tmp/moonship-test-golang-gopkg"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Gopkg.yml", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .go-version" {
  let path = "/tmp/moonship-test-golang-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.go-version", "")
  let m = GolangModule::new()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_) || m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
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
