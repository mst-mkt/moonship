///|
async test "name" {
  let m : &@ms.PromptModule = TerraformModule::default()
  assert_eq(m.name(), "terraform")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[terraform]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = TerraformModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-terraform-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = TerraformModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .tf extension" {
  let path = "/tmp/moonship-test-terraform-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.tf", "")
  let m = TerraformModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Terraform project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_terraform_version: terraform" {
  assert_eq(parse_terraform_version("Terraform v1.5.7"), "1.5.7")
}

///|
test "parse_terraform_version: opentofu" {
  assert_eq(parse_terraform_version("OpenTofu v1.6.0"), "1.6.0")
}

///|
test "parse_terraform_version: with extra info" {
  assert_eq(parse_terraform_version("Terraform v1.5.7 on linux_amd64"), "1.5.7")
}

///|
test "parse_terraform_version: empty" {
  assert_eq(parse_terraform_version(""), "")
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
