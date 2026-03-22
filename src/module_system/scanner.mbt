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

  loop start {
    i => if i < len && pred(char_at(s, i)) { continue i + 1 } else { break i }
  }
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
fn find_matching(s : String, start : Int, open : Char, close : Char) -> Int? {
  let len = s.length()

  loop (start + 1, 1) {
    (i, depth) =>
      if i >= len || depth <= 0 {
        break if depth == 0 { Some(i) } else { None }
      } else {
        let ch = char_at(s, i)
        if ch == '\\' && i + 1 < len {
          continue (i + 2, depth)
        } else if ch == open {
          continue (i + 1, depth + 1)
        } else if ch == close {
          let new_depth = depth - 1
          if new_depth == 0 {
            break Some(i)
          } else {
            continue (i + 1, new_depth)
          }
        } else {
          continue (i + 1, depth)
        }
      }
  }
}
