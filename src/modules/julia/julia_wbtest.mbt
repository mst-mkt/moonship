///|
async test "name" {
  let m : &@ms.PromptModule = JuliaModule::new()
  assert_eq(m.name(), "julia")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[julia]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = JuliaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-julia-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = JuliaModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Project.toml" {
  let path = "/tmp/moonship-test-julia-project"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Project.toml", "")
  let m = JuliaModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Manifest.toml" {
  let path = "/tmp/moonship-test-julia-manifest"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Manifest.toml", "")
  let m = JuliaModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .jl extension" {
  let path = "/tmp/moonship-test-julia-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.jl", "")
  let m = JuliaModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Julia project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_julia_version: standard" {
  assert_eq(parse_julia_version("julia version 1.8.5"), "1.8.5")
}

///|
test "parse_julia_version: rc" {
  assert_eq(parse_julia_version("julia version 1.9.0-rc1"), "1.9.0-rc1")
}

///|
test "parse_julia_version: empty" {
  assert_eq(parse_julia_version(""), "")
}

///|
test "parse_julia_version: too few words" {
  assert_eq(parse_julia_version("julia version"), "")
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
