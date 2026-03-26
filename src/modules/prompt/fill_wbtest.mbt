///|
async test "name" {
  let m : &@ms.PromptModule = FillModule::default()
  assert_eq(m.name(), "fill")
}

///|
async test "execute: produces fill segment" {
  let m = FillModule::default()
  let ctx = @context.Context::new(cwd="/tmp")

  guard m.execute(ctx) is Output(out) else {
    fail("Expected Output")
    return
  }

  assert_eq(out.segments.length(), 1)
  assert_true(out.segments[0].is_fill)
  assert_eq(out.segments[0].text, ".")
}

///|
async test "execute: disabled" {
  let config = @config.Config::from_toml(
    (
      #|[fill]
      #|disabled = true
    ),
  )
  let m = FillModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp")

  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: custom symbol" {
  let config = @config.Config::from_toml(
    (
      #|[fill]
      #|symbol = "-"
    ),
  )
  let m = FillModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp")

  guard m.execute(ctx) is Output(out) else {
    fail("Expected Output")
    return
  }

  assert_eq(out.segments[0].text, "-")
  assert_true(out.segments[0].is_fill)
}
