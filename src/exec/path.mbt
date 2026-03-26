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
  loop s.length() - 1 {
    i =>
      if i < 0 {
        break None
      } else if s[i].unsafe_to_char() == '/' {
        break Some(i)
      } else {
        continue i - 1
      }
  }
}

///|
pub fn parse_leading_int(s : String) -> Int {
  s
  .iter()
  .take_while(fn(c) { c >= '0' && c <= '9' })
  .fold(init=0, fn(acc, c) { acc * 10 + (c.to_int() - '0'.to_int()) })
}
