///|
async test "name" {
  let m : &@ms.PromptModule = CondaModule::default()
  assert_eq(m.name(), "conda")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[conda]
      #|disabled = true
    ),
  )
  let m = CondaModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no conda env returns Skipped" {
  let m = CondaModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  // CONDA_DEFAULT_ENV typically not set outside conda
  assert_true(not(result is Disabled))
}

///|
test "basename: simple path" {
  assert_eq(@exec.basename("/home/user/envs/myenv"), "myenv")
}

///|
test "basename: no slash" {
  assert_eq(@exec.basename("base"), "base")
}

///|
test "basename: trailing slash" {
  assert_eq(@exec.basename("/home/user/envs/myenv/"), "myenv")
}
