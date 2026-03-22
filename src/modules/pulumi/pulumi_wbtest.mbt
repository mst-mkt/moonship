///|
async test "name" {
  let m : &@ms.PromptModule = PulumiModule::default()
  assert_eq(m.name(), "pulumi")
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-pulumi-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PulumiModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Pulumi.yaml" {
  let path = "/tmp/moonship-test-pulumi-yaml"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Pulumi.yaml", "")
  let m = PulumiModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Pulumi project detected"))
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
