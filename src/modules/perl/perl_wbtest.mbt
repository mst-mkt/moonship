///|
async test "name" {
  let m : &@ms.PromptModule = PerlModule::new()
  assert_eq(m.name(), "perl")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[perl]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PerlModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-perl-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PerlModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Makefile.PL" {
  let path = "/tmp/moonship-test-perl-makefile"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Makefile.PL", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects cpanfile" {
  let path = "/tmp/moonship-test-perl-cpanfile"
  setup_dir(path)
  @fs.write_string_to_file(path + "/cpanfile", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .pl extension" {
  let path = "/tmp/moonship-test-perl-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/script.pl", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .pm extension" {
  let path = "/tmp/moonship-test-perl-pm"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Module.pm", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Build.PL" {
  let path = "/tmp/moonship-test-perl-buildpl"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Build.PL", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects META.json" {
  let path = "/tmp/moonship-test-perl-metajson"
  setup_dir(path)
  @fs.write_string_to_file(path + "/META.json", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .pod extension" {
  let path = "/tmp/moonship-test-perl-pod"
  setup_dir(path)
  @fs.write_string_to_file(path + "/doc.pod", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .perl-version" {
  let path = "/tmp/moonship-test-perl-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.perl-version", "")
  let m = PerlModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Perl project detected"))
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
