///|
async test "name" {
  let m : &@ms.PromptModule = OCamlModule::new()
  assert_eq(m.name(), "ocaml")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[ocaml]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OCamlModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-ocaml-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OCamlModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects dune" {
  let path = "/tmp/moonship-test-ocaml-dune"
  setup_dir(path)
  @fs.write_string_to_file(path + "/dune", "")
  let m = OCamlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OCaml project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .ml extension" {
  let path = "/tmp/moonship-test-ocaml-ml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.ml", "")
  let m = OCamlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OCaml project detected"))
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
