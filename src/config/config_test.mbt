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
  guard config.get_raw_module("character") is Some(table)
  assert_eq(
    @config.get_toml_string(table, "success_symbol"),
    Some("[→](bold blue)"),
  )
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
test "module disabled from TOML" {
  let toml =
    #|[git_branch]
    #|disabled = true
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("git_branch") is Some(table)
  assert_eq(@config.get_toml_bool(table, "disabled"), Some(true))
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
  guard config.get_raw_module("custom_module") is Some(table)
  assert_eq(@config.get_toml_string(table, "format"), Some("$text"))
  assert_eq(@config.get_toml_string(table, "style"), Some("bold"))
  assert_eq(@config.get_toml_string(table, "key"), Some("value"))
}

///|
test "empty TOML is default" {
  let config = @config.Config::from_toml("")
  let default = @config.Config::default()
  assert_eq(config.format, default.format)
  assert_eq(config.scan_timeout, default.scan_timeout)
}

///|
test "numeric property from TOML" {
  let toml =
    #|[directory]
    #|truncation_length = 5
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("directory") is Some(table)
  assert_eq(@config.get_toml_int(table, "truncation_length"), Some(5))
}

///|
test "get_toml_int: missing key returns None" {
  let toml =
    #|[directory]
    #|style = "bold"
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("directory") is Some(table)
  assert_true(@config.get_toml_int(table, "nonexistent") is None)
}

///|
test "async: parsed from TOML" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("git_status") is Some(table)
  assert_eq(@config.get_toml_bool(table, "async"), Some(true))
}

///|
test "async: false when explicitly set" {
  let toml =
    #|[git_status]
    #|async = false
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("git_status") is Some(table)
  assert_eq(@config.get_toml_bool(table, "async"), Some(false))
}

///|
test "async: unset module has no raw entry" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  assert_true(config.get_raw_module("git_branch") is None)
}

///|
test "async: serialized to TOML when true" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  let output = config.to_toml()
  assert_true(output.contains("async = true"))
}

///|
test "async: not serialized in default config" {
  let config = @config.Config::default()
  let output = config.to_toml()
  assert_false(output.contains("async"))
}

///|
test "async: roundtrip TOML" {
  let toml =
    #|[git_status]
    #|async = true
    #|[git_branch]
    #|async = false
    #|
  let config = @config.Config::from_toml(toml)
  let output = config.to_toml()
  let reparsed = @config.Config::from_toml(output)
  guard reparsed.get_raw_module("git_status") is Some(gs)
  guard reparsed.get_raw_module("git_branch") is Some(gb)
  assert_eq(@config.get_toml_bool(gs, "async"), Some(true))
  assert_eq(@config.get_toml_bool(gb, "async"), Some(false))
}

///|
test "unknown module with async" {
  let toml =
    #|[my_custom]
    #|async = true
    #|format = "$text"
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("my_custom") is Some(table)
  assert_eq(@config.get_toml_bool(table, "async"), Some(true))
  assert_eq(@config.get_toml_string(table, "format"), Some("$text"))
}

///|
test "get_toml_string_array: parses array" {
  let toml =
    #|[python]
    #|detect_files = ["requirements.txt", "setup.py"]
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("python") is Some(table)
  guard @config.get_toml_string_array(table, "detect_files") is Some(files)
  assert_eq(files.length(), 2)
  assert_eq(files[0], "requirements.txt")
  assert_eq(files[1], "setup.py")
}

///|
test "get_toml_string_array: missing key returns None" {
  let toml =
    #|[python]
    #|symbol = "🐍 "
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("python") is Some(table)
  assert_true(@config.get_toml_string_array(table, "detect_files") is None)
}

///|
test "from_json: parses JSONC config" {
  let json =
    #|{
    #|  // This is a comment
    #|  "format": "$character",
    #|  "scan_timeout": 100,
    #|  "character": {
    #|    "disabled": true,
    #|    "symbol": "→"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  assert_eq(config.format, "$character")
  assert_eq(config.scan_timeout, 100)
  guard config.get_raw_module("character") is Some(table)
  assert_eq(@config.get_toml_bool(table, "disabled"), Some(true))
  assert_eq(@config.get_toml_string(table, "symbol"), Some("→"))
}

///|
test "from_json: integer and boolean types" {
  let json =
    #|{
    #|  "directory": {
    #|    "truncation_length": 5,
    #|    "truncate_to_repo": true
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("directory") is Some(table)
  assert_eq(@config.get_toml_int(table, "truncation_length"), Some(5))
  assert_eq(@config.get_toml_bool(table, "truncate_to_repo"), Some(true))
}

///|
test "from_json: string array" {
  let json =
    #|{
    #|  "python": {
    #|    "detect_files": ["requirements.txt", "setup.py"]
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("python") is Some(table)
  guard @config.get_toml_string_array(table, "detect_files") is Some(files)
  assert_eq(files.length(), 2)
  assert_eq(files[0], "requirements.txt")
  assert_eq(files[1], "setup.py")
}

///|
test "from_json: defaults applied for missing fields" {
  let config = @config.Config::from_json("{}")
  assert_eq(config.format, "$all")
  assert_eq(config.scan_timeout, 30)
  assert_eq(config.command_timeout, 500)
}

///|
test "from_json: null values are skipped" {
  let json =
    #|{
    #|  "character": {
    #|    "symbol": "→",
    #|    "style": null
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("character") is Some(table)
  assert_eq(@config.get_toml_string(table, "symbol"), Some("→"))
  assert_true(@config.get_toml_string(table, "style") is None)
}

///|
test "default config has no raw_modules" {
  let config = @config.Config::default()
  assert_true(config.get_raw_module("character") is None)
  assert_true(config.get_raw_module("directory") is None)
}
