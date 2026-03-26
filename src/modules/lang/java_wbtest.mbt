///|
async test "name" {
  let m : &@ms.PromptModule = JavaModule::default()
  assert_eq(m.name(), "java")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[java]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = JavaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-java-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = JavaModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects pom.xml" {
  let path = "/tmp/moonship-test-java-pom"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/pom.xml", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects build.gradle.kts" {
  let path = "/tmp/moonship-test-java-gradle"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/build.gradle.kts", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .java extension" {
  let path = "/tmp/moonship-test-java-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.java", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects build.sbt" {
  let path = "/tmp/moonship-test-java-sbt"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/build.sbt", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .sdkmanrc" {
  let path = "/tmp/moonship-test-java-sdkman"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.sdkmanrc", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .java-version" {
  let path = "/tmp/moonship-test-java-version"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.java-version", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .jar extension" {
  let path = "/tmp/moonship-test-java-jar"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.jar", "")
  let m = JavaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Disabled) else { fail("expected non-Disabled") }
  if result is Output(out) {
    assert_true(out.render().contains("☕"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_java_version: openjdk 17" {
  assert_eq(
    parse_java_version(
      "OpenJDK 64-Bit Server VM (17.0.1+12-39) for linux-amd64 JRE (17.0.1+12-39), built on Oct  8 2021",
    ),
    "17.0.1",
  )
}

///|
test "parse_java_version: java 8" {
  assert_eq(
    parse_java_version(
      "Java HotSpot(TM) 64-Bit Server VM (25.131-b11) for linux-amd64 JRE (1.8.0_131-b11), built on Mar 15 2017",
    ),
    "1.8.0",
  )
}

///|
test "parse_java_version: openj9" {
  assert_eq(
    parse_java_version(
      "Eclipse OpenJ9 VM (0.33.0) for linux-amd64 JRE (17.0.5+8), built on Oct 2022",
    ),
    "17.0.5",
  )
}

///|
test "parse_java_version: graalvm" {
  assert_eq(
    parse_java_version(
      "Java HotSpot(TM) 64-Bit Server VM GraalVM CE 22.3.0 (build 17.0.5+9-jvmci-22.3-b08, mixed mode, sharing) for linux-amd64 JRE (17.0.5+9-jvmci-22.3-b08), built on Oct 2022",
    ),
    "17.0.5",
  )
}

///|
test "parse_java_version: empty" {
  assert_eq(parse_java_version(""), "")
}

///|
test "parse_java_version: unknown format" {
  assert_eq(parse_java_version("something unexpected"), "")
}

///|
test "extract_version: digits and dots" {
  assert_eq(extract_version("17.0.1+12-39", 0), "17.0.1")
}

///|
test "extract_version: from offset" {
  assert_eq(extract_version("JRE (1.8.0_131)", 5), "1.8.0")
}

///|
test "extract_version: empty after offset" {
  assert_eq(extract_version("abc", 3), "")
}
