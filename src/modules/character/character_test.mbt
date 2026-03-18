///|
test "status 0: bold green symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("32"))
}

///|
test "non-zero status: bold red symbol" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("31"))
}

///|
test "success and error differ" {
  let m : &@ms.PromptModule = CharacterModule::new()

  let ok = m
    .execute(@context.Context::new(cwd="/tmp", status=0))
    .unwrap()
    .render()
  let err = m
    .execute(@context.Context::new(cwd="/tmp", status=1))
    .unwrap()
    .render()

  assert_true(ok != err)
}

///|
test "disabled returns None" {
  let config = @config.Config::from_toml(
    (
      #|[character]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m : &@ms.PromptModule = CharacterModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "custom symbol via config" {
  let config = @config.Config::from_toml(
    (
      #|[character]
      #|success_symbol = "[→](bold blue)"
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", status=0, config~)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("→"))
  assert_true(rendered.contains("34"))
}

///|
test "name" {
  let m : &@ms.PromptModule = CharacterModule::new()
  assert_eq(m.name(), "character")
}
