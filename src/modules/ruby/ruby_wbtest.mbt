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
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = RubyModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Gemfile" {
  let path = "/tmp/moonship-test-ruby-gemfile"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Gemfile", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .ruby-version" {
  let path = "/tmp/moonship-test-ruby-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.ruby-version", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .rb extension" {
  let path = "/tmp/moonship-test-ruby-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.rb", "")
  let m = RubyModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Ruby project detected"))
  @test_util.remove_dir_recursive(path)
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


