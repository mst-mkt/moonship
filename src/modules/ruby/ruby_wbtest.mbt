///|
async test "name" {
  let m : &@ms.PromptModule = RubyModule::default()
  assert_eq(m.name(), "ruby")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[ruby]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = RubyModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-ruby-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RubyModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Gemfile" {
  let path = "/tmp/moonship-test-ruby-gemfile"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Gemfile", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .ruby-version" {
  let path = "/tmp/moonship-test-ruby-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.ruby-version", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .rb extension" {
  let path = "/tmp/moonship-test-ruby-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/app.rb", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_ruby_version: standard with patch" {
  assert_eq(
    parse_ruby_version(
      "ruby 2.1.10p492 (2016-04-01 revision 54464) [x86_64-darwin19.0]",
    ),
    "2.1.10",
  )
}

///|
test "parse_ruby_version: modern without patch" {
  assert_eq(
    parse_ruby_version(
      "ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-linux]",
    ),
    "3.2.2",
  )
}

///|
test "parse_ruby_version: with patch number" {
  assert_eq(
    parse_ruby_version(
      "ruby 2.7.8p225 (2023-03-30 revision 1f4d455848) [x86_64-linux]",
    ),
    "2.7.8",
  )
}

///|
test "parse_ruby_version: empty" {
  assert_eq(parse_ruby_version(""), "")
}

///|
test "parse_ruby_version: single word" {
  assert_eq(parse_ruby_version("ruby"), "")
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
