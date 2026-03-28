///|
pub fn add_v_prefix(s : String) -> String {
  if s.is_empty() || s.has_prefix("v") || s.has_prefix("V") {
    s
  } else {
    "v\{s}"
  }
}

///|
pub fn strip_v_prefix(s : String) -> String {
  if s.has_prefix("v") || s.has_prefix("V") {
    s[1:].to_string()
  } else {
    s
  }
}

///|
pub fn find_semver(output : String) -> String {
  output
  .split(" ")
  .map(fn(part) { extract_semver(part.to_string()) })
  .find_first(fn(ver) { not(ver.is_empty()) })
  .unwrap_or("")
}

///|
fn extract_semver(s : String) -> String {
  guard s.iter().next() is Some('0'..='9') else { return "" }

  let (prefix, dots) = s
    .iter()
    .take_while(fn(c) { (c >= '0' && c <= '9') || c == '.' })
    .fold(init=(StringBuilder::new(), 0), fn(acc, c) {
      let (buf, dots) = acc
      buf.write_char(c)
      (buf, dots + Bool::to_int(c == '.'))
    })

  guard dots >= 2 else { return "" }

  let result = prefix.to_string()
  if result.has_suffix(".") {
    result[:result.length() - 1].to_string()
  } else {
    result
  }
}

///|
pub fn format_version(raw : String, version_format : String) -> String {
  guard not(raw.is_empty()) else { return "" }

  let stripped = strip_v_prefix(raw)

  let (major, minor, patch) = match split_to_strings(stripped, ".") {
    [major, minor, patch, ..] => (major, minor, patch)
    [major, minor] => (major, minor, "")
    [major] => (major, "", "")
    _ => ("", "", "")
  }

  version_format
  .replace(old="${raw}", new=stripped)
  .replace(old="${major}", new=major)
  .replace(old="${minor}", new=minor)
  .replace(old="${patch}", new=patch)
}

///|
pub fn detect_compiler_name(
  output : String,
  compilers : Array[(String, String)],
) -> String {
  compilers
  .iter()
  .find_first(fn(pair) { output.contains(pair.1) })
  .map(fn(pair) { pair.0 })
  .unwrap_or("")
}
