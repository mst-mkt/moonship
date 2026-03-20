///|
async test "name" {
  let m : &@ms.PromptModule = JobsModule::new()
  assert_eq(m.name(), "jobs")
}

// --- execute ---

///|
async test "execute: no jobs returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp", jobs=0)
  let m = JobsModule::new()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: one job shows symbol without number" {
  let ctx = @context.Context::new(cwd="/tmp", jobs=1)
  let m = JobsModule::new()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let texts = out.segments.map(fn(s) { s.text }).join("")
  assert_true(texts.contains("✦"))
  assert_false(texts.contains("1"))
}

///|
async test "execute: jobs at threshold shows number" {
  let ctx = @context.Context::new(cwd="/tmp", jobs=2)
  let m = JobsModule::new()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("✦"))
  assert_true(rendered.contains("2"))
}

///|
async test "execute: custom number_threshold=1" {
  let config = @config.Config::from_toml(
    (
      #|[jobs]
      #|number_threshold = 1
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", jobs=1, config~)
  let m = JobsModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  assert_true(out.render().contains("1"))
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[jobs]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", jobs=1, config~)
  let m = JobsModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}
