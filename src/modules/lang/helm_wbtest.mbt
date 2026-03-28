///|
async test "name" {
  let m : &@ms.PromptModule = helm_defaults()
  assert_eq(m.name(), "helm")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[helm]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = SimpleLangModule::from_config(config, helm_defaults())
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-helm-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = helm_defaults()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Chart.yaml" {
  let path = "/tmp/moonship-test-helm-chart"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Chart.yaml", "")
  let m = helm_defaults()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Helm project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_helm_version: typical output" {
  assert_eq(parse_helm_version("v3.12.3+g3a31588"), "3.12.3")
}

///|
test "parse_helm_version: without v prefix" {
  assert_eq(parse_helm_version("3.12.3+g3a31588"), "3.12.3")
}

///|
test "parse_helm_version: empty" {
  assert_eq(parse_helm_version(""), "")
}
