///|
async test "name" {
  let m : &@ms.PromptModule = DenoModule::default()
  assert_eq(m.name(), "deno")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[deno]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = DenoModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-deno-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = DenoModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects deno.json" {
  let path = "/tmp/moonship-test-deno-json"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/deno.json", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects deno.jsonc" {
  let path = "/tmp/moonship-test-deno-jsonc"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/deno.jsonc", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects deno.lock" {
  let path = "/tmp/moonship-test-deno-lock"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/deno.lock", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects mod.ts" {
  let path = "/tmp/moonship-test-deno-modts"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/mod.ts", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects deps.ts" {
  let path = "/tmp/moonship-test-deno-depsts"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/deps.ts", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects mod.js" {
  let path = "/tmp/moonship-test-deno-modjs"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/mod.js", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects deps.js" {
  let path = "/tmp/moonship-test-deno-depsjs"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/deps.js", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Deno project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_deno_version: standard output" {
  assert_eq(parse_deno_version("deno 1.40.2"), "1.40.2")
}

///|
test "parse_deno_version: v2" {
  assert_eq(parse_deno_version("deno 2.0.0"), "2.0.0")
}

///|
test "parse_deno_version: empty" {
  assert_eq(parse_deno_version(""), "")
}

///|
test "parse_deno_version: single word" {
  assert_eq(parse_deno_version("deno"), "")
}
