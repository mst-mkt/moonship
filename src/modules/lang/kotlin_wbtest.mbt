///|
async test "name" {
  let m : &@ms.PromptModule = KotlinModule::default()
  assert_eq(m.name(), "kotlin")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[kotlin]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = KotlinModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-kotlin-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = KotlinModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .kt extension" {
  let path = "/tmp/moonship-test-kotlin-kt"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.kt", "")
  let m = KotlinModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Kotlin project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("🅺"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .kts extension" {
  let path = "/tmp/moonship-test-kotlin-kts"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/build.gradle.kts", "")
  let m = KotlinModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Kotlin project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("🅺"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_kotlin_version: runtime" {
  assert_eq(
    parse_kotlin_version("Kotlin version 1.4.21-release-411 (JRE 14.0.1+7)"),
    "1.4.21",
  )
}

///|
test "parse_kotlin_version: compiler" {
  assert_eq(
    parse_kotlin_version("info: kotlinc-jvm 1.4.21 (JRE 14.0.1+7)"),
    "1.4.21",
  )
}

///|
test "parse_kotlin_version: empty" {
  assert_eq(parse_kotlin_version(""), "")
}

///|
test "parse_kotlin_version: no version" {
  assert_eq(parse_kotlin_version("no version here"), "")
}
