///|
async test "status 0: bold green symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("32"))
}

///|
async test "non-zero status: bold red symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("31"))
}

///|
async test "success and error differ" {
  let m : &@ms.PromptModule = CharacterModule::new()

  let ok = m
    .execute(@context.Context::new(cwd="/tmp", status=0))
    .output()
    .unwrap()
    .render()
  let err = m
    .execute(@context.Context::new(cwd="/tmp", status=1))
    .output()
    .unwrap()
    .render()

  assert_true(ok != err)
}

///|
async test "disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[character]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m : &@ms.PromptModule = CharacterModule::from_config(config)

  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "custom symbol via config" {
  let config = @config.Config::from_toml(
    (
      #|[character]
      #|success_symbol = "[→](bold blue)"
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", status=0, config~)
  let m : &@ms.PromptModule = CharacterModule::from_config(config)

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("→"))
  assert_true(rendered.contains("34"))
}

///|
async test "name" {
  let m : &@ms.PromptModule = CharacterModule::new()
  assert_eq(m.name(), "character")
}

///|
async test "vicmd keymap: shows vimcmd symbol" {
  let ctx = @context.Context::new(cwd="/tmp", keymap="vicmd")
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  assert_true(out.render().contains("❮"))
}

///|
async test "visual keymap: shows visual symbol" {
  let ctx = @context.Context::new(cwd="/tmp", keymap="visual")
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❮"))
  assert_true(rendered.contains("33"))
}

///|
async test "unknown keymap: falls back to success symbol" {
  let ctx = @context.Context::new(cwd="/tmp", keymap="viins", status=0)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Output(out) else { fail("expected output") }

  assert_true(out.render().contains("❯"))
}
