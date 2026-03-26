///|
async test "name" {
  let m : &@ms.PromptModule = GradleModule::default()
  assert_eq(m.name(), "gradle")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[gradle]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GradleModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-gradle-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = GradleModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .gradle extension" {
  let path = "/tmp/moonship-test-gradle-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/build.gradle", "")
  let m = GradleModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Gradle project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_gradle_wrapper_version: standard" {
  let content =
    #|distributionBase=GRADLE_USER_HOME
    #|distributionPath=wrapper/dists
    #|distributionUrl=https\://services.gradle.org/distributions/gradle-7.5.1-bin.zip
    #|zipStoreBase=GRADLE_USER_HOME
    #|zipStorePath=wrapper/dists
  assert_eq(parse_gradle_wrapper_version(content), "7.5.1")
}

///|
test "parse_gradle_wrapper_version: all distribution" {
  let content =
    #|distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
  assert_eq(parse_gradle_wrapper_version(content), "8.4")
}

///|
test "parse_gradle_wrapper_version: empty" {
  assert_eq(parse_gradle_wrapper_version(""), "")
}

///|
test "parse_gradle_wrapper_version: no distribution url" {
  assert_eq(parse_gradle_wrapper_version("some=other\nlines=here"), "")
}


