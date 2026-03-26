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
  assert_eq(table.get_string("success_symbol"), Some("[→](bold blue)"))
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
  assert_eq(table.get_bool("disabled"), Some(true))
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
  assert_eq(table.get_string("format"), Some("$text"))
  assert_eq(table.get_string("style"), Some("bold"))
  assert_eq(table.get_string("key"), Some("value"))
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
  assert_eq(table.get_int("truncation_length"), Some(5))
}

///|
test "get_int: missing key returns None" {
  let toml =
    #|[directory]
    #|style = "bold"
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("directory") is Some(table)
  assert_true(table.get_int("nonexistent") is None)
}

///|
test "async: parsed from TOML" {
  let toml =
    #|[git_status]
    #|async = true
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("git_status") is Some(table)
  assert_eq(table.get_bool("async"), Some(true))
}

///|
test "async: false when explicitly set" {
  let toml =
    #|[git_status]
    #|async = false
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("git_status") is Some(table)
  assert_eq(table.get_bool("async"), Some(false))
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
  assert_eq(gs.get_bool("async"), Some(true))
  assert_eq(gb.get_bool("async"), Some(false))
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
  assert_eq(table.get_bool("async"), Some(true))
  assert_eq(table.get_string("format"), Some("$text"))
}

///|
test "get_string_array: parses array" {
  let toml =
    #|[python]
    #|detect_files = ["requirements.txt", "setup.py"]
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("python") is Some(table)
  guard table.get_string_array("detect_files") is Some(files)
  assert_eq(files.length(), 2)
  assert_eq(files[0], "requirements.txt")
  assert_eq(files[1], "setup.py")
}

///|
test "get_string_array: missing key returns None" {
  let toml =
    #|[python]
    #|symbol = "🐍 "
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("python") is Some(table)
  assert_true(table.get_string_array("detect_files") is None)
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
  assert_eq(table.get_bool("disabled"), Some(true))
  assert_eq(table.get_string("symbol"), Some("→"))
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
  assert_eq(table.get_int("truncation_length"), Some(5))
  assert_eq(table.get_bool("truncate_to_repo"), Some(true))
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
  guard table.get_string_array("detect_files") is Some(files)
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
  assert_eq(table.get_string("symbol"), Some("→"))
  assert_true(table.get_string("style") is None)
}

///|
test "add_newline: parsed and roundtripped" {
  let toml =
    #|add_newline = false
    #|
  let config = @config.Config::from_toml(toml)
  assert_eq(config.add_newline, false)
  let output = config.to_toml()
  assert_true(output.contains("add_newline = false"))
}

///|
test "get_string_array: mixed types returns None" {
  let json =
    #|{
    #|  "python": {
    #|    "detect_files": ["a.py", 42]
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("python") is Some(table)
  assert_true(table.get_string_array("detect_files") is None)
}

///|
test "escape_string: handles special characters" {
  assert_eq(@config.escape_string("hello"), "\"hello\"")
  assert_eq(@config.escape_string("he\"llo"), "\"he\\\"llo\"")
  assert_eq(@config.escape_string("a\\b"), "\"a\\\\b\"")
  assert_eq(@config.escape_string("a\nb"), "\"a\\nb\"")
  assert_eq(@config.escape_string("a\tb"), "\"a\\tb\"")
  assert_eq(@config.escape_string("a\rb"), "\"a\\rb\"")
}

///|
test "from_json to to_toml cross-format" {
  let json =
    #|{
    #|  "format": "$character",
    #|  "git_status": {
    #|    "async": true,
    #|    "style": "red"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  let toml_output = config.to_toml()
  let reparsed = @config.Config::from_toml(toml_output)
  assert_eq(reparsed.format, "$character")
  guard reparsed.get_raw_module("git_status") is Some(table)
  assert_eq(table.get_bool("async"), Some(true))
  assert_eq(table.get_string("style"), Some("red"))
}

///|
test "to_toml: arrays serialized correctly" {
  let json =
    #|{
    #|  "python": {
    #|    "detect_files": ["requirements.txt", "setup.py"]
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  let output = config.to_toml()
  assert_true(output.contains("[python]"))
  assert_true(
    output.contains("detect_files = [\"requirements.txt\", \"setup.py\"]"),
  )
}

///|
test "empty module section uses defaults" {
  let toml =
    #|[python]
    #|
  let config = @config.Config::from_toml(toml)
  guard config.get_raw_module("python") is Some(table)
  assert_true(table.get_string("symbol") is None)
}

///|
test "default config has no raw_modules" {
  let config = @config.Config::default()
  assert_true(config.get_raw_module("character") is None)
  assert_true(config.get_raw_module("directory") is None)
}

// --- Config parsing error cases ---

///|
test "from_toml: invalid syntax raises" {
  let result = try? @config.Config::from_toml("[invalid")
  assert_true(result is Err(_))
}

///|
test "from_json: invalid syntax raises" {
  let result = try? @config.Config::from_json("{{bad")
  assert_true(result is Err(_))
}

///|
test "from_json: non-object root raises" {
  let result = try? @config.Config::from_json("[1,2,3]")
  assert_true(result is Err(_))
}

///|
test "from_json: empty string raises" {
  let result = try? @config.Config::from_json("")
  assert_true(result is Err(_))
}

///|
test "from_toml: empty string is valid default config" {
  let config = @config.Config::from_toml("")
  let default = @config.Config::default()
  assert_eq(config.format, default.format)
  assert_eq(config.scan_timeout, default.scan_timeout)
  assert_eq(config.command_timeout, default.command_timeout)
  assert_eq(config.cache_ttl, default.cache_ttl)
  assert_eq(config.add_newline, default.add_newline)
}

// --- ModuleTable accessor edge cases ---

///|
test "get_string: on non-string value returns None" {
  let json =
    #|{
    #|  "mod": {
    #|    "count": 42
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("mod") is Some(table)
  assert_true(table.get_string("count") is None)
}

///|
test "get_int: on non-int value returns None" {
  let json =
    #|{
    #|  "mod": {
    #|    "name": "hello"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("mod") is Some(table)
  assert_true(table.get_int("name") is None)
}

///|
test "get_bool: on non-bool value returns None" {
  let json =
    #|{
    #|  "mod": {
    #|    "count": 42
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("mod") is Some(table)
  assert_true(table.get_bool("count") is None)
}

///|
test "get_string_array: on non-array value returns None" {
  let json =
    #|{
    #|  "mod": {
    #|    "name": "hello"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("mod") is Some(table)
  assert_true(table.get_string_array("name") is None)
}

///|
test "get_string_array: empty array returns Some([])" {
  let json =
    #|{
    #|  "mod": {
    #|    "items": []
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("mod") is Some(table)
  guard table.get_string_array("items") is Some(items)
  assert_eq(items.length(), 0)
}

// --- Config from JSON edge cases ---

///|
test "from_json: null values filtered at top level" {
  let json =
    #|{
    #|  "format": "$all",
    #|  "character": null
    #|}
  let config = @config.Config::from_json(json)
  assert_true(config.get_raw_module("character") is None)
}

///|
test "from_json: nested objects become modules" {
  let json =
    #|{
    #|  "git_status": {
    #|    "style": "red",
    #|    "disabled": false
    #|  },
    #|  "directory": {
    #|    "truncation_length": 3
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("git_status") is Some(gs)
  guard config.get_raw_module("directory") is Some(dir)
  assert_eq(gs.get_string("style"), Some("red"))
  assert_eq(gs.get_bool("disabled"), Some(false))
  assert_eq(dir.get_int("truncation_length"), Some(3))
}

///|
test "from_json: arrays in module config" {
  let json =
    #|{
    #|  "node": {
    #|    "detect_files": ["package.json", ".nvmrc"],
    #|    "symbol": "⬢"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  guard config.get_raw_module("node") is Some(table)
  guard table.get_string_array("detect_files") is Some(files)
  assert_eq(files.length(), 2)
  assert_eq(files[0], "package.json")
  assert_eq(files[1], ".nvmrc")
  assert_eq(table.get_string("symbol"), Some("⬢"))
}

// --- Config warnings ---

///|
test "Config::default has empty warnings" {
  let config = @config.Config::default()
  assert_eq(config.warnings.length(), 0)
}

///|
test "with_warnings sets warnings correctly" {
  let config = @config.Config::default()
  let warned = config.with_warnings(["warn1", "warn2"])
  assert_eq(warned.warnings.length(), 2)
  assert_eq(warned.warnings[0], "warn1")
  assert_eq(warned.warnings[1], "warn2")

  assert_eq(warned.format, config.format)
}

// --- Config to_toml edge cases ---

///|
test "to_toml: module with array values" {
  let json =
    #|{
    #|  "rust": {
    #|    "detect_files": ["Cargo.toml", "Cargo.lock"],
    #|    "symbol": "🦀"
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  let output = config.to_toml()
  assert_true(output.contains("[rust]"))
  assert_true(
    output.contains("detect_files = [\"Cargo.toml\", \"Cargo.lock\"]"),
  )
  assert_true(output.contains("symbol = \"🦀\""))
}

///|
test "to_toml: module with all field types" {
  let json =
    #|{
    #|  "example": {
    #|    "name": "test",
    #|    "count": 10,
    #|    "enabled": true,
    #|    "tags": ["a", "b"]
    #|  }
    #|}
  let config = @config.Config::from_json(json)
  let output = config.to_toml()
  assert_true(output.contains("[example]"))
  assert_true(output.contains("name = \"test\""))
  assert_true(output.contains("count = 10"))
  assert_true(output.contains("enabled = true"))
  assert_true(output.contains("tags = [\"a\", \"b\"]"))
}

///|
test "parse palette from TOML" {
  let config = @config.Config::from_toml(
    (
      #|palette = "catppuccin"
      #|
      #|[palettes.catppuccin]
      #|mustard = "#af8700"
      #|sky = "51"
    ),
  )
  assert_eq(config.palette, "catppuccin")

  let active = config.get_active_palette()
  assert_eq(active.get("mustard"), Some("#af8700"))
  assert_eq(active.get("sky"), Some("51"))
}

///|
test "get_active_palette: no palette set returns empty" {
  let config = @config.Config::default()
  let active = config.get_active_palette()
  assert_eq(active.length(), 0)
}

///|
test "palettes not in raw_modules" {
  let config = @config.Config::from_toml(
    (
      #|[palettes.custom]
      #|red = "#ff0000"
    ),
  )
  assert_true(config.get_raw_module("palettes") is None)
}

///|
test "palettes roundtrip in to_toml" {
  let config = @config.Config::from_toml(
    (
      #|palette = "custom"
      #|
      #|[palettes.custom]
      #|mustard = "#af8700"
    ),
  )
  let toml = config.to_toml()
  assert_true(toml.contains("[palettes.custom]"))
  assert_true(toml.contains("mustard"))
}

///|
test "get_active_palette: unknown palette returns empty" {
  let config = @config.Config::from_toml(
    (
      #|palette = "nonexistent"
    ),
  )
  let active = config.get_active_palette()
  assert_eq(active.length(), 0)
}
