///|
async test "name" {
  let m : &@ms.PromptModule = ScalaModule::default()
  assert_eq(m.name(), "scala")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[scala]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ScalaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-scala-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ScalaModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects build.sbt" {
  let path = "/tmp/moonship-test-scala-sbt"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/build.sbt", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Scala project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .scala extension" {
  let path = "/tmp/moonship-test-scala-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.scala", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Scala project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .scalaenv" {
  let path = "/tmp/moonship-test-scala-env"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.scalaenv", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Scala project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_scalac_version: scala 2" {
  assert_eq(
    parse_scalac_version("Scala compiler version 2.13.5 -- Copyright"),
    "2.13.5",
  )
}

///|
test "parse_scalac_version: scala 3" {
  assert_eq(
    parse_scalac_version("Scala compiler version 3.0.0-RC1 -- Copyright"),
    "3.0.0-RC1",
  )
}

///|
test "parse_scalac_version: empty" {
  assert_eq(parse_scalac_version(""), "")
}

///|
test "parse_scalac_version: too few words" {
  assert_eq(parse_scalac_version("Scala compiler version"), "")
}
