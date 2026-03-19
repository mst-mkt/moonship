///|
fn char_at(s : String, i : Int) -> Char {
  s[i].unsafe_to_char()
}

///|
fn is_ident_char(c : Char) -> Bool {
  match c {
    'a'..='z' | 'A'..='Z' | '_' | '0'..='9' => true
    _ => false
  }
}

///|
fn unescape(ch : Char) -> String {
  match ch {
    'n' => "\n"
    't' => "\t"
    _ => ch.to_string()
  }
}

///|
fn scan_while(s : String, start : Int, pred : (Char) -> Bool) -> Int {
  let len = s.length()
  let mut i = start

  while i < len && pred(char_at(s, i)) {
    i += 1
  }

  i
}

///|
fn scan_ident(s : String, start : Int) -> (String, Int) {
  let end = scan_while(s, start, is_ident_char)

  if end > start {
    (s[start:end].to_string(), end)
  } else {
    ("", start)
  }
}

///|
fn find_matching_bracket(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut depth = 1
  let mut i = start + 1

  while i < len && depth > 0 {
    match char_at(s, i) {
      '[' => depth += 1
      ']' => depth -= 1
      _ => ()
    }
    if depth > 0 {
      i += 1
    }
  }

  if depth == 0 {
    Some(i)
  } else {
    None
  }
}
