///|
fn identity(s : String) -> String {
  s
}

///|
fn nth_word(output : String, n : Int) -> String {
  let parts = @exec.split_to_strings(output, " ")
  if parts.length() > n {
    parts[n]
  } else {
    ""
  }
}

///|
fn last_word(output : String) -> String {
  output.split(" ").fold(init="", fn(_prev, s) { s.to_string() })
}

///|
fn parse_dart_version(output : String) -> String {
  nth_word(output, 3)
}

///|
fn parse_swift_version(output : String) -> String {
  output
  .split(" ")
  .fold(init=(false, ""), fn(state, part) {
    let (found_version, result) = state
    let word = part.to_string()

    if found_version && result.is_empty() {
      (true, word)
    } else {
      (found_version || word == "version", result)
    }
  }).1
}

///|
fn parse_helm_version(output : String) -> String {
  let stripped = @exec.strip_v_prefix(output)

  match stripped.find("+") {
    Some(idx) => stripped[:idx].to_string()
    None => stripped
  }
}

///|
fn parse_nim_version(output : String) -> String {
  output
  .split(" ")
  .find_first(fn(part) {
    let s = part.to_string()

    not(s.is_empty()) &&
    s.iter().next() is Some('0'..='9') &&
    s.iter().all(fn(c) { (c >= '0' && c <= '9') || c == '.' })
  })
  .map(fn(s) { s.to_string() })
  .unwrap_or("")
}

///|
fn parse_opa_version(output : String) -> String {
  let first_line = match output.find("\n") {
    Some(idx) => output[:idx].to_string()
    None => output
  }

  last_word(first_line)
}

///|
fn parse_cobol_version(output : String) -> String {
  let found = output
    .split(" ")
    .find_first(fn(part) {
      let s = part.to_string()

      not(s.is_empty()) && s.iter().next() is Some('0'..='9')
    })
    .map(fn(s) { s.to_string() })
    .unwrap_or("")

  guard not(found.is_empty()) else { return "" }

  extract_version_digits(found)
}

///|
fn extract_version_digits(s : String) -> String {
  s
  .iter()
  .take_while(fn(c) { (c >= '0' && c <= '9') || c == '.' })
  .fold(init=StringBuilder::new(), fn(buf, c) {
    buf.write_char(c)
    buf
  })
  .to_string()
}
