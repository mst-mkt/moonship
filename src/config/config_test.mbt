///|
test "デフォルト設定の to_toml が parse 可能" {
  let config = @config.Config::default()
  let toml_str = config.to_toml()
  let parsed = @config.Config::from_toml(toml_str)
  assert_eq(parsed.format, config.format)
  assert_eq(parsed.scan_timeout, config.scan_timeout)
  assert_eq(parsed.command_timeout, config.command_timeout)
}

///|
test "TOML からモジュール設定を読み込み" {
  let toml =
    #|[character]
    #|success_symbol = "[→](bold blue)"
    #|
  let config = @config.Config::from_toml(toml)
  let ch = config.get_module("character")
  assert_eq(ch.get_prop("success_symbol"), "[→](bold blue)")
  // error_symbol はデフォルトのまま
  assert_eq(ch.get_prop("error_symbol"), "[❯](bold red)")
}

///|
test "トップレベル設定の上書き" {
  let toml =
    #|format = "$character"
    #|scan_timeout = 2000
    #|
  let config = @config.Config::from_toml(toml)
  assert_eq(config.format, "$character")
  assert_eq(config.scan_timeout, 2000)
  assert_eq(config.command_timeout, 500) // デフォルト値
}

///|
test "モジュールの disabled" {
  let toml =
    #|[git_branch]
    #|disabled = true
    #|
  let config = @config.Config::from_toml(toml)
  let gb = config.get_module("git_branch")
  assert_true(gb.disabled)
  // format はデフォルトのまま
  assert_eq(gb.format, "[$branch]($style) ")
}

///|
test "未知のモジュールを追加" {
  let toml =
    #|[custom_module]
    #|format = "$text"
    #|style = "bold"
    #|key = "value"
    #|
  let config = @config.Config::from_toml(toml)
  let m = config.get_module("custom_module")
  assert_eq(m.format, "$text")
  assert_eq(m.style, "bold")
  assert_eq(m.get_prop("key"), "value")
}

///|
test "空 TOML はデフォルト設定" {
  let config = @config.Config::from_toml("")
  let default = @config.Config::default()
  assert_eq(config.format, default.format)
  assert_eq(config.scan_timeout, default.scan_timeout)
}

///|
test "数値プロパティ" {
  let toml =
    #|[directory]
    #|truncation_length = 5
    #|
  let config = @config.Config::from_toml(toml)
  let dir = config.get_module("directory")
  assert_eq(dir.get_prop("truncation_length"), "5")
}
