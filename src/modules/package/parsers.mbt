///|
fn parse_json_version(content : String) -> String {
  extract_json_string_field(content, "version")
}

///|
fn extract_json_string_field(content : String, field : String) -> String {
  let key = "\"" + field + "\""
  guard content.find(key) is Some(idx) else { return "" }

  let after_key = idx + key.length()
  guard find_char_from(content, ':', after_key) is Some(colon) else {
    return ""
  }
  guard find_char_from(content, '"', colon + 1) is Some(quote_start) else {
    return ""
  }
  guard find_char_from(content, '"', quote_start + 1) is Some(quote_end) else {
    return ""
  }

  content[quote_start + 1:quote_end].to_string()
}

///|
fn parse_cargo_toml(content : String) -> String {
  extract_toml_version(content, path=["package", "version"])
}

///|
fn parse_pyproject_toml(content : String) -> String {
  extract_toml_version(content, path=["project", "version"])
}

///|
fn parse_julia_toml(content : String) -> String {
  extract_toml_version(content, path=["version"])
}

///|
fn extract_toml_version(content : String, path~ : Array[String]) -> String {
  let parsed = @toml.parse(content) catch { _ => return "" }
  guard parsed is TomlTable(table) else { return "" }

  let mut current : Map[String, @toml.TomlValue] = table

  for i = 0; i < path.length() - 1; i = i + 1 {
    guard current.get(path[i]) is Some(TomlTable(next)) else { return "" }
    current = next
  }

  guard current.get(path[path.length() - 1]) is Some(TomlString(v)) else {
    return ""
  }

  v
}

///|
fn extract_version_line(content : String) -> String {
  for line in content.split("\n") {
    let s = line.to_string()
    guard has_version_key(s) else { continue }

    let value = extract_value_after_separator(s)
    if not(value.is_empty()) {
      return value
    }
  }

  ""
}

///|
fn has_version_key(line : String) -> Bool {
  let len = line.length()
  let mut i = 0

  while i < len {
    let ch = line[i].unsafe_to_char()
    if ch != ' ' && ch != '\t' {
      break
    }
    i += 1
  }

  line[i:].to_string().has_prefix("version")
}

///|
fn extract_value_after_separator(line : String) -> String {
  let separators = [":=", "=", ":"]

  for sep in separators {
    guard line.find(sep) is Some(idx) else { continue }

    let after = idx + sep.length()
    let raw = line[after:].to_string()
    return strip_quotes(raw)
  }

  ""
}

///|
fn strip_quotes(s : String) -> String {
  let buf = StringBuilder::new()

  for ch in s {
    match ch {
      '"' | '\'' | ' ' | '\t' | ',' => ()
      _ => buf.write_char(ch)
    }
  }

  buf.to_string()
}

///|
fn parse_r_description(content : String) -> String {
  let prefix = "Version:"

  for line in content.split("\n") {
    let s = line.to_string()
    if s.has_prefix(prefix) {
      return strip_quotes(s[prefix.length():].to_string())
    }
  }

  ""
}

///|
fn extract_xml_version(content : String) -> String {
  let open_tag = "<version>"
  let close_tag = "</version>"

  guard content.find(open_tag) is Some(start) else { return "" }

  let value_start = start + open_tag.length()
  guard content.find(close_tag) is Some(end) else { return "" }
  guard end > value_start else { return "" }

  content[value_start:end].to_string()
}

///|
fn find_file_with_extension(dir : String, ext : String) -> String {
  let entries = @fs.read_dir(dir) catch { _ => return "" }

  for entry in entries {
    if entry.has_suffix(ext) {
      return dir + "/" + entry
    }
  }

  ""
}

///|
fn find_char_from(s : String, target : Char, start : Int) -> Int? {
  let len = s.length()

  for i = start; i < len; i = i + 1 {
    if s[i].unsafe_to_char() == target {
      return Some(i)
    }
  }

  None
}
