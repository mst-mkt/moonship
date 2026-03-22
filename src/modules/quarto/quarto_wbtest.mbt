///|
async test "name" {
  let m : &@ms.PromptModule = QuartoModule::default()
  assert_eq(m.name(), "quarto")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[quarto]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = QuartoModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-quarto-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = QuartoModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects _quarto.yml" {
  let path = "/tmp/moonship-test-quarto-yml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/_quarto.yml", "")
  let m = QuartoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Quarto project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .qmd extension" {
  let path = "/tmp/moonship-test-quarto-qmd"
  setup_dir(path)
  @fs.write_string_to_file(path + "/doc.qmd", "")
  let m = QuartoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Quarto project detected"))
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
