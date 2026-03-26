///|
async test "name" {
  let m : &@ms.PromptModule = BufModule::default()
  assert_eq(m.name(), "buf")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[buf]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = BufModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-buf-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = BufModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects buf.yaml" {
  let path = "/tmp/moonship-test-buf-yaml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/buf.yaml", "")
  let m = BufModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Buf project detected"))
  @test_util.remove_dir_recursive(path)
}


