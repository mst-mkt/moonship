///|
async test "name" {
  let m : &@ms.PromptModule = ShlvlModule::default()
  assert_eq(m.name(), "shlvl")
}

///|
async test "execute: disabled by default" {
  let m = ShlvlModule::default()
  let ctx = @context.Context::new(cwd="/tmp", shlvl=3)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: below threshold returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", shlvl=1, config~)
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: at threshold returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", shlvl=2, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: above threshold returns Output" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", shlvl=5, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: custom threshold" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
      #|threshold = 4
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx_below = @context.Context::new(cwd="/tmp", shlvl=3, config~)
  assert_true(m.execute(ctx_below) is Skipped(_))

  let ctx_at = @context.Context::new(cwd="/tmp", shlvl=4, config~)
  assert_true(m.execute(ctx_at) is Output(_))
}

///|
async test "execute: repeat mode" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
      #|threshold = 1
      #|repeat = true
      #|symbol = "~"
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", shlvl=3, config~)
  assert_true(m.execute(ctx) is Output(_))
}

///|
async test "execute: repeat with offset reduces to zero returns Skipped" {
  let config = @config.Config::from_toml(
    (
      #|[shlvl]
      #|disabled = false
      #|threshold = 1
      #|repeat = true
      #|repeat_offset = 3
    ),
  )
  let m = ShlvlModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", shlvl=3, config~)
  assert_true(m.execute(ctx) is Skipped(_))
}
