///|
async test "name" {
  let m : &@ms.PromptModule = PulumiModule::default()
  assert_eq(m.name(), "pulumi")
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-pulumi-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PulumiModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Pulumi.yaml" {
  let path = "/tmp/moonship-test-pulumi-yaml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Pulumi.yaml", "")
  let m = PulumiModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Pulumi project detected"))
  @test_util.remove_dir_recursive(path)
}


