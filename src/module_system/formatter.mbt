///|
fn char_at(s : String, i : Int) -> Char {
  s[i].unsafe_to_char()
}

///|
/// Parse format string and replace $variables and [text](style) patterns
pub fn format_string(
  template : String,
  vars : Map[String, String],
  style : @terminal.Style,
) -> Array[Segment] {
  let segments : Array[Segment] = []
  let len = template.length()
  let mut i = 0

  while i < len {
    match char_at(template, i) {
      '\\' if i + 1 < len => {
        segments.push(Segment::new(unescape(char_at(template, i + 1)), style~))
        i += 2
      }
      '$' => {
        let (var_name, end) = scan_ident(template, i + 1)
        if not(var_name.is_empty()) {
          match vars.get(var_name) {
            Some(val) =>
              parse_inline_styled(val, style).each(fn(seg) {
                segments.push(seg)
              })
            None => ()
          }
        }
        i = end
      }
      '[' =>
        match parse_styled_segment(template, i, vars) {
          Some((segs, next_i)) => {
            segs.each(fn(seg) { segments.push(seg) })
            i = next_i
          }
          None => {
            segments.push(Segment::new("[", style~))
            i += 1
          }
        }
      _ => {
        let end = scan_while(template, i, fn(c) {
          c != '$' && c != '[' && c != '\\'
        })
        segments.push(Segment::new(template[i:end].to_string(), style~))
        i = end
      }
    }
  }

  segments
}

///|
/// Parse [text](style) and apply variable substitution inside
fn parse_styled_segment(
  s : String,
  start : Int,
  vars : Map[String, String],
) -> (Array[Segment], Int)? {
  guard find_matching_bracket(s, start) is Some(cb) else { return None }

  let inner_text = s[start + 1:cb].to_string()
  let after_bracket = cb + 1

  guard after_bracket < s.length() && char_at(s, after_bracket) == '(' else {
    return None
  }

  let style_end = scan_while(s, after_bracket + 1, fn(c) { c != ')' })
  guard style_end < s.length() else { return None }

  let style_spec = s[after_bracket + 1:style_end].to_string()
  let resolved_style = resolve_style(style_spec, vars)
  let resolved_text = substitute_vars(inner_text, vars)
  if resolved_text.is_empty() {
    return Some(([], style_end + 1))
  }

  Some(([Segment::new(resolved_text, style=resolved_style)], style_end + 1))
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

///|
fn resolve_style(spec : String, vars : Map[String, String]) -> @terminal.Style {
  let resolved = if spec.has_prefix("$") {
    vars.get(spec[1:].to_string()).unwrap_or(spec)
  } else {
    spec
  }

  @terminal.parse_style(resolved)
}

///|
fn substitute_vars(text : String, vars : Map[String, String]) -> String {
  let buf = StringBuilder::new()
  let len = text.length()
  let mut i = 0

  while i < len {
    if char_at(text, i) == '\\' && i + 1 < len {
      buf.write_string(unescape(char_at(text, i + 1)))
      i += 2
    } else if char_at(text, i) == '$' {
      let (var_name, end) = scan_ident(text, i + 1)
      if not(var_name.is_empty()) {
        buf.write_string(vars.get(var_name).unwrap_or(""))
      }
      i = end
    } else {
      buf.write_char(char_at(text, i))
      i += 1
    }
  }

  buf.to_string()
}

///|
fn parse_inline_styled(
  text : String,
  default_style : @terminal.Style,
) -> Array[Segment] {
  let segments : Array[Segment] = []
  let len = text.length()
  let empty_vars : Map[String, String] = {}
  let mut i = 0

  while i < len {
    if char_at(text, i) == '[' {
      match parse_styled_segment(text, i, empty_vars) {
        Some((segs, next_i)) => {
          segs.each(fn(seg) { segments.push(seg) })
          i = next_i
        }
        None => {
          segments.push(Segment::new("[", style=default_style))
          i += 1
        }
      }
    } else {
      let end = scan_while(text, i, fn(c) { c != '[' })
      segments.push(Segment::new(text[i:end].to_string(), style=default_style))
      i = end
    }
  }

  segments
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
/// Extract module names from a format string like "$directory$git_branch"
pub fn extract_module_names(format : String) -> Array[String] {
  let names : Array[String] = []
  let len = format.length()
  let mut i = 0

  while i < len {
    if char_at(format, i) == '$' {
      let (name, end) = scan_ident(format, i + 1)
      if not(name.is_empty()) {
        names.push(name)
      }
      i = end
    } else {
      i += 1
    }
  }

  names
}
