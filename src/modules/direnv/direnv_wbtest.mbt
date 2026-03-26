///|
async test "name" {
  let m : &@ms.PromptModule = DirenvModule::default()
  assert_eq(m.name(), "direnv")
}

///|
async test "execute: disabled by default" {
  let m = DirenvModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no envrc returns Skipped" {
  let path = "/tmp/moonship-test-direnv-empty"
  @test_util.setup_dir(path)
  let config = @config.Config::from_toml(
    (
      #|[direnv]
      #|disabled = false
    ),
  )
  let m = DirenvModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .envrc" {
  let path = "/tmp/moonship-test-direnv-envrc"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/.envrc", "")
  let config = @config.Config::from_toml(
    (
      #|[direnv]
      #|disabled = false
    ),
  )
  let m = DirenvModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no direnv detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_direnv_status: loaded and allowed" {
  let output =
    #|Found RC allowed 0
    #|Loaded RC allowed 0
  let (loaded, allowed) = parse_direnv_status(output)
  assert_true(loaded)
  assert_eq(allowed, "allowed")
}

///|
test "parse_direnv_status: loaded but denied" {
  let output =
    #|Found RC allowed 2
    #|Loaded RC allowed 2
  let (loaded, allowed) = parse_direnv_status(output)
  assert_true(loaded)
  assert_eq(allowed, "denied")
}

///|
test "parse_direnv_status: not loaded" {
  let output = "No .envrc or .env loaded"
  let (loaded, allowed) = parse_direnv_status(output)
  assert_false(loaded)
  assert_eq(allowed, "not_allowed")
}

///|
test "parse_direnv_status: not allowed" {
  let output =
    #|Found RC allowed 1
  let (loaded, allowed) = parse_direnv_status(output)
  assert_true(loaded)
  assert_eq(allowed, "not_allowed")
}

///|
test "parse_direnv_status: legacy format" {
  let output =
    #|Found RC allowed true
  let (loaded, allowed) = parse_direnv_status(output)
  assert_true(loaded)
  assert_eq(allowed, "allowed")
}

///|
test "parse_direnv_status: empty" {
  let (loaded, allowed) = parse_direnv_status("")
  assert_false(loaded)
  assert_eq(allowed, "not_allowed")
}


