///|
fn parse_json_version(content : String) -> String {
  extract_json_string_field(content, "version")
}

///|
fn extract_json_string_field(content : String, field : String) -> String {
  let key = "\"\{field}\""
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
  guard path.length() > 0 else { return "" }

  let init : (Map[String, @toml.TomlValue]?, _) = (Some(table), true)

  let (final_table, _) = path[:path.length() - 1]
    .iter()
    .fold(init~, fn(acc, key) {
      match acc {
        (Some(current), true) =>
          match current.get(key) {
            Some(TomlTable(next)) => (Some(next), true)
            _ => (None, false)
          }
        _ => acc
      }
    })

  guard final_table is Some(current) else { return "" }
  guard current.get(path[path.length() - 1]) is Some(TomlString(v)) else {
    return ""
  }

  v
}

///|
fn extract_version_line(content : String) -> String {
  @exec.split_to_strings(content, "\n")
  .iter()
  .find_first(fn(s) {
    has_version_key(s) && not(extract_value_after_separator(s).is_empty())
  })
  .map(fn(s) { extract_value_after_separator(s) })
  .unwrap_or("")
}

///|
fn has_version_key(line : String) -> Bool {
  line.trim_start(chars=" \t").to_string().has_prefix("version")
}

///|
fn extract_value_after_separator(line : String) -> String {
  [":=", "=", ":"]
  .iter()
  .filter_map(fn(sep) {
    line
    .find(sep)
    .map(fn(idx) { strip_quotes(line[idx + sep.length():].to_string()) })
  })
  .find_first(fn(_) { true })
  .unwrap_or("")
}

///|
fn strip_quotes(s : String) -> String {
  s
  .iter()
  .filter(fn(ch) {
    match ch {
      '"' | '\'' | ' ' | '\t' | ',' => false
      _ => true
    }
  })
  .fold(init=StringBuilder::new(), fn(buf, ch) {
    buf.write_char(ch)
    buf
  })
  .to_string()
}

///|
fn parse_r_description(content : String) -> String {
  let prefix = "Version:"

  @exec.split_to_strings(content, "\n")
  .iter()
  .find_first(fn(s) { s.has_prefix(prefix) })
  .map(fn(s) { strip_quotes(s[prefix.length():].to_string()) })
  .unwrap_or("")
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

  entries
  .iter()
  .find_first(fn(entry) { entry.has_suffix(ext) })
  .map(fn(entry) { "\{dir}/\{entry}" })
  .unwrap_or("")
}

///|
fn find_char_from(s : String, target : Char, start : Int) -> Int? {
  s[start:].to_string().find(target.to_string()).map(fn(i) { i + start })
}
