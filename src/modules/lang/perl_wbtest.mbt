///|
async test "name" {
  let m : &@ms.PromptModule = PerlModule::default()
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
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PerlModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Makefile.PL" {
  let path = "/tmp/moonship-test-perl-makefile"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Makefile.PL", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects cpanfile" {
  let path = "/tmp/moonship-test-perl-cpanfile"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/cpanfile", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .pl extension" {
  let path = "/tmp/moonship-test-perl-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/script.pl", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .pm extension" {
  let path = "/tmp/moonship-test-perl-pm"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Module.pm", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Build.PL" {
  let path = "/tmp/moonship-test-perl-buildpl"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Build.PL", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects META.json" {
  let path = "/tmp/moonship-test-perl-metajson"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/META.json", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .pod extension" {
  let path = "/tmp/moonship-test-perl-pod"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/doc.pod", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .perl-version" {
  let path = "/tmp/moonship-test-perl-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.perl-version", "")
  let m = PerlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Perl project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
