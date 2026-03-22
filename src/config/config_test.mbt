///|
test "default to_toml roundtrip" {
  let config = @config.Config::default()
  let toml_str = config.to_toml()
  let parsed = @config.Config::from_toml(toml_str)
  assert_eq(parsed.format, config.format)
  assert_eq(parsed.scan_timeout, config.scan_timeout)
  assert_eq(parsed.command_timeout, config.command_timeout)
  assert_eq(parsed.cache_ttl, config.cache_ttl)
}

///|
test "module config from TOML" {
  let toml =
    #|[character]
    #|success_symbol = "[→](bold blue)"
    #|
  let config = @config.Config::from_toml(toml)
  let ch = config.get_module("character")
  assert_eq(ch.get_prop("success_symbol"), "[→](bold blue)")
  assert_eq(ch.get_prop("error_symbol"), "[❯](bold red)")
}

///|
test "top-level override" {
  let toml =
    #|format = "$character"
    #|scan_timeout = 2000
    #|
  let config = @config.Config::from_toml(toml)
  assert_eq(config.format, "$character")
  assert_eq(config.scan_timeout, 2000)
  assert_eq(config.command_timeout, 500)
}

///|
test "module disabled" {
  let toml =
    #|[git_branch]
    #|disabled = true
    #|
  let config = @config.Config::from_toml(toml)
  let gb = config.get_module("git_branch")
  assert_true(gb.disabled)
  assert_eq(gb.format, "on [$symbol$branch(:$remote_branch)]($style) ")
}

///|
test "unknown module added" {
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
test "empty TOML is default" {
  let config = @config.Config::from_toml("")
  let default = @config.Config::default()
  assert_eq(config.format, default.format)
  assert_eq(config.scan_timeout, default.scan_timeout)
}

///|
test "numeric property" {
  let toml =
    #|[directory]
    #|truncation_length = 5
    #|
  let config = @config.Config::from_toml(toml)
  let dir = config.get_module("directory")
  assert_eq(dir.get_prop("truncation_length"), "5")
}

///|
test "get_int_prop: valid" {
  let config = @config.Config::default()
  let dir = config.get_module("directory")
  assert_eq(dir.get_int_prop("truncation_length"), 3)
}

///|
test "get_int_prop: missing key uses default" {
  let config = @config.Config::default()
  let dir = config.get_module("directory")
  assert_eq(dir.get_int_prop("nonexistent", default=42), 42)
}

///|
test "async_render: defaults to false" {
  let config = @config.Config::default()
  assert_false(config.get_module("git_status").async_render)
  assert_false(config.get_module("directory").async_render)
  assert_false(config.get_module("character").async_render)
}

///|
test "async_render: parsed from TOML" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  assert_true(config.get_module("git_status").async_render)
}

///|
test "async_render: false when explicitly set" {
  let toml =
    #|[git_status]
    #|async = false
    #|
  let config = @config.Config::from_toml(toml)
  assert_false(config.get_module("git_status").async_render)
}

///|
test "async_render: unaffected modules remain false" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  assert_false(config.get_module("git_branch").async_render)
  assert_false(config.get_module("directory").async_render)
}

///|
test "async_render: not stored in props" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  let gs = config.get_module("git_status")
  assert_eq(gs.get_prop("async"), "")
}

///|
test "async_render: serialized to TOML when true" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  let output = config.to_toml()
  assert_true(output.contains("async = true"))
}

///|
test "async_render: not serialized when false" {
  let config = @config.Config::default()
  let output = config.to_toml()
  assert_false(output.contains("async"))
}

///|
test "async_render: roundtrip TOML" {
  let toml =
    #|[git_status]
    #|async = true
    #|[git_branch]
    #|async = false
    #|
  let config = @config.Config::from_toml(toml)
  let output = config.to_toml()
  let reparsed = @config.Config::from_toml(output)
  assert_true(reparsed.get_module("git_status").async_render)
  assert_false(reparsed.get_module("git_branch").async_render)
}

///|
test "async_render: unknown module with async" {
  let toml =
    #|[my_custom]
    #|async = true
    #|format = "$text"
    #|
  let config = @config.Config::from_toml(toml)
  assert_true(config.get_module("my_custom").async_render)
  assert_eq(config.get_module("my_custom").format, "$text")
}

///|
test "get_int_prop: invalid value uses default" {
  let toml =
    #|[directory]
    #|truncation_length = "abc"
    #|
  let config = @config.Config::from_toml(toml)
  let dir = config.get_module("directory")
  assert_eq(dir.get_int_prop("truncation_length", default=3), 3)
}
