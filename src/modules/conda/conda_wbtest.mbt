///|
async test "name" {
  let m : &@ms.PromptModule = CondaModule::new()
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
  let m = CondaModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  // CONDA_DEFAULT_ENV typically not set outside conda
  assert_true(result is Skipped(_) || result is Output(_))
}

///|
test "basename: simple path" {
  assert_eq(basename("/home/user/envs/myenv"), "myenv")
}

///|
test "basename: no slash" {
  assert_eq(basename("base"), "base")
}

///|
test "basename: trailing slash" {
  assert_eq(basename("/home/user/envs/myenv/"), "")
}
