///|
async test "name" {
  let m : &@ms.PromptModule = OsModule::new()
  assert_eq(m.name(), "os")
}

///|
async test "execute: disabled by default" {
  let m = OsModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: enabled detects OS" {
  let config = @config.Config::from_toml(
    (
      #|[os]
      #|disabled = false
    ),
  )
  let m = OsModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let result = m.execute(ctx)
  assert_true(result is Output(_))
}

///|
test "strip_quotes: quoted" {
  assert_eq(strip_quotes("\"arch\""), "arch")
}

///|
test "strip_quotes: unquoted" {
  assert_eq(strip_quotes("arch"), "arch")
}

///|
test "strip_quotes: empty" {
  assert_eq(strip_quotes(""), "")
}

///|
test "get_os_symbol: arch" {
  assert_eq(get_os_symbol("arch"), "🎗️ ")
}

///|
test "get_os_symbol: ubuntu" {
  assert_eq(get_os_symbol("ubuntu"), "🎯 ")
}

///|
test "get_os_symbol: unknown" {
  assert_eq(get_os_symbol("something"), "🐧 ")
}
