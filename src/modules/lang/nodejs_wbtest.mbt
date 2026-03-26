///|
async test "name" {
  let m : &@ms.PromptModule = NodejsModule::default()
  assert_eq(m.name(), "nodejs")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[nodejs]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = NodejsModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-nodejs-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = NodejsModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects package.json" {
  let path = "/tmp/moonship-test-nodejs-pkg"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{}")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .node-version file" {
  let path = "/tmp/moonship-test-nodejs-nodever"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.node-version", "20.0.0")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .js extension" {
  let path = "/tmp/moonship-test-nodejs-jsext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/index.js", "")
  let m = NodejsModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)

  guard not(result is Skipped("no Node.js project detected")) else {
    fail("project should be detected")
  }

  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }

  @test_util.remove_dir_recursive(path)
}

// --- semver / version parsing edge cases ---

///|
test "parse_semver: basic" {
  assert_eq(parse_semver("1.2.3"), (1, 2, 3))
}

///|
test "parse_semver: partial" {
  assert_eq(parse_semver("1.2"), (1, 2, 0))
}

///|
test "parse_semver: empty" {
  assert_eq(parse_semver(""), (0, 0, 0))
}

///|
test "parse_semver: prerelease" {
  assert_eq(parse_semver("1.2.3-beta"), (1, 2, 3))
}

///|
test "semver_cmp: equal" {
  assert_eq(semver_cmp((1, 2, 3), (1, 2, 3)), 0)
}

///|
test "semver_cmp: major diff" {
  assert_true(semver_cmp((2, 0, 0), (1, 0, 0)) > 0)
}

///|
test "check_version_satisfies: empty req" {
  assert_true(check_version_satisfies("v20.0.0", ""))
}

///|
test "check_version_satisfies: caret" {
  assert_true(check_version_satisfies("v18.5.0", "^18.0.0"))
  assert_false(check_version_satisfies("v19.0.0", "^18.0.0"))
}

///|
test "check_version_satisfies: tilde" {
  assert_true(check_version_satisfies("v18.2.1", "~18.2.0"))
  assert_false(check_version_satisfies("v18.3.0", "~18.2.0"))
}

///|
test "check_version_satisfies: gte" {
  assert_true(check_version_satisfies("v18.0.0", ">=18.0.0"))
  assert_false(check_version_satisfies("v17.0.0", ">=18.0.0"))
}

///|
test "check_version_satisfies: or" {
  assert_true(check_version_satisfies("v16.0.0", "^16.0.0 || ^18.0.0"))
  assert_false(check_version_satisfies("v17.0.0", "^16.0.0 || ^18.0.0"))
}

///|
test "caret_satisfies: zero major" {
  assert_true(caret_satisfies((0, 2, 5), (0, 2, 0)))
  assert_false(caret_satisfies((0, 3, 0), (0, 2, 0)))
}

///|
test "extract_json_value: no colon" {
  assert_eq(extract_json_value("no colon"), "")
}

///|
test "extract_json_value: valid" {
  assert_eq(extract_json_value(": \">=18\""), ">=18")
}

///|
test "extract_json_value: empty value" {
  assert_eq(extract_json_value(": \"\""), "")
}
