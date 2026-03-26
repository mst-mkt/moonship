///|
async test "name" {
  let m : &@ms.PromptModule = HaskellModule::default()
  assert_eq(m.name(), "haskell")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[haskell]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = HaskellModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-haskell-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = HaskellModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects stack.yaml" {
  let path = "/tmp/moonship-test-haskell-stack"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/stack.yaml", "")
  let m = HaskellModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects cabal.project" {
  let path = "/tmp/moonship-test-haskell-cabal"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/cabal.project", "")
  let m = HaskellModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .hs extension" {
  let path = "/tmp/moonship-test-haskell-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Main.hs", "")
  let m = HaskellModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .cabal extension" {
  let path = "/tmp/moonship-test-haskell-cabal-ext"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.cabal", "")
  let m = HaskellModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Haskell project detected"))
  @test_util.remove_dir_recursive(path)
}


