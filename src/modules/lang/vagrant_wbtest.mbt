///|
async test "name" {
  let m : &@ms.PromptModule = vagrant_defaults()
  assert_eq(m.name(), "vagrant")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[vagrant]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, vagrant_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-vagrant-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = vagrant_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Vagrantfile" {
  let path = "/tmp/moonship-test-vagrant-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Vagrantfile", "")
  let m = vagrant_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Vagrant project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}
