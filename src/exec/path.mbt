///|
fn trim_trailing_slash(path : String) -> String {
  if path.has_suffix("/") {
    path[:path.length() - 1].to_string()
  } else {
    path
  }
}

///|
pub fn basename(path : String) -> String {
  let trimmed = trim_trailing_slash(path)

  match last_slash(trimmed) {
    Some(idx) => trimmed[idx + 1:].to_string()
    None => trimmed
  }
}

///|
pub fn parent_dir(path : String) -> String {
  let trimmed = trim_trailing_slash(path)

  match last_slash(trimmed) {
    Some(idx) => trimmed[:idx].to_string()
    None => ""
  }
}

///|
pub fn last_slash(s : String) -> Int? {
  s
  .iter()
  .fold(init=((None : Int?), 0), fn(state, ch) {
    let (last, i) = state
    (if ch == '/' { Some(i) } else { last }, i + 1)
  }).0
}

///|
pub fn split_to_strings(s : String, sep : String) -> Array[String] {
  s.split(sep).map(fn(v) { v.to_string() }).collect()
}

///|
pub fn parse_leading_int(s : String) -> Int {
  s
  .iter()
  .take_while(fn(c) { c >= '0' && c <= '9' })
  .fold(init=0, fn(acc, c) { acc * 10 + (c.to_int() - '0'.to_int()) })
}
