///|
test "成功: status 0 で緑の太字シンボル" {
  let ctx = @context.Context::new(cwd="/tmp", status=0)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("32")) // green
}

///|
test "失敗: 非ゼロ status で赤の太字シンボル" {
  let ctx = @context.Context::new(cwd="/tmp", status=1)
  let m : &@ms.PromptModule = CharacterModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("31")) // red
}

///|
test "成功と失敗で異なる出力" {
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
test "無効化されたモジュールは None" {
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
test "設定でカスタムシンボル" {
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
  assert_true(rendered.contains("34")) // blue
}

///|
test "モジュール名" {
  let m : &@ms.PromptModule = CharacterModule::new()
  assert_eq(m.name(), "character")
}
