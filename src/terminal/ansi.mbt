///|
fn color_base_code(c : Color) -> Int? {
  match c {
    Default | Ansi256(_) | Hex(_) => None
    Black => Some(0)
    Red => Some(1)
    Green => Some(2)
    Yellow => Some(3)
    Blue => Some(4)
    Purple => Some(5)
    Cyan => Some(6)
    White => Some(7)
    BrightBlack => Some(60)
    BrightRed => Some(61)
    BrightGreen => Some(62)
    BrightYellow => Some(63)
    BrightBlue => Some(64)
    BrightPurple => Some(65)
    BrightCyan => Some(66)
    BrightWhite => Some(67)
  }
}

///|
fn color_to_code(c : Color, is_fg : Bool) -> String? {
  let base = if is_fg { 30 } else { 40 }
  let ext = if is_fg { "38" } else { "48" }

  match c {
    Default => None
    Ansi256(n) => Some("\{ext};5;\{n}")
    Hex(rgb) => {
      let r = (rgb >> 16) & 0xFF
      let g = (rgb >> 8) & 0xFF
      let b = rgb & 0xFF
      Some("\{ext};2;\{r};\{g};\{b}")
    }
    _ => color_base_code(c).map(fn(code) { (base + code).to_string() })
  }
}

///|
fn style_codes(style : Style) -> Array[String] {
  let attr_codes : Array[String] = [
      (style.bold, "1"),
      (style.dimmed, "2"),
      (style.italic, "3"),
      (style.underline, "4"),
      (style.inverted, "7"),
      (style.strikethrough, "9"),
    ]
    .iter()
    .filter_map(fn(pair) { if pair.0 { Some(pair.1) } else { None } })
    .collect()

  let color_codes : Array[String] = [
      color_to_code(style.fg, true),
      color_to_code(style.bg, false),
    ]
    .iter()
    .filter_map(fn(c) { c })
    .collect()

  attr_codes + color_codes
}

///|
pub fn stylize(text : String, style : Style) -> String {
  guard not(text.is_empty()) else { return "" }

  let codes = style_codes(style)
  guard not(codes.is_empty()) else { return text }

  let code_str = codes.join(";")
  "\u001b[\{code_str}m\{text}\u001b[0m"
}

///|
pub fn parse_color(name : String) -> Color {
  match name {
    "black" => Black
    "red" => Red
    "green" => Green
    "yellow" => Yellow
    "blue" => Blue
    "purple" => Purple
    "cyan" => Cyan
    "white" => White
    "bright-black" | "brightblack" => BrightBlack
    "bright-red" | "brightred" => BrightRed
    "bright-green" | "brightgreen" => BrightGreen
    "bright-yellow" | "brightyellow" => BrightYellow
    "bright-blue" | "brightblue" => BrightBlue
    "bright-purple" | "brightpurple" => BrightPurple
    "bright-cyan" | "brightcyan" => BrightCyan
    "bright-white" | "brightwhite" => BrightWhite
    _ => parse_color_value(name)
  }
}

///|
fn parse_color_value(name : String) -> Color {
  let hex_str = if name.has_prefix("#") { name[1:].to_string() } else { name }

  if hex_str.length() == 6 {
    if parse_hex(hex_str) is Some(v) {
      return Hex(v)
    }
  }

  parse_ansi256(hex_str).unwrap_or(Default)
}

///|
fn parse_ansi256(s : String) -> Color? {
  let n = @strconv.parse_int(s) catch { _ => return None }
  if n >= 0 && n <= 255 {
    Some(Ansi256(n))
  } else {
    None
  }
}

///|
fn parse_hex(s : String) -> Int? {
  let mut result = 0

  for ch in s {
    let digit = match ch {
      '0'..='9' => ch.to_int() - '0'.to_int()
      'a'..='f' => ch.to_int() - 'a'.to_int() + 10
      'A'..='F' => ch.to_int() - 'A'.to_int() + 10
      _ => return None
    }
    result = result * 16 + digit
  }

  Some(result)
}

///|
pub fn parse_style(spec : String) -> Style {
  spec
  .split(" ")
  .fold(init=Style::default(), fn(style, part) {
    apply_style_part(style, part.to_string())
  })
}

///|
fn apply_style_part(style : Style, part : String) -> Style {
  match part {
    "none" => Style::default()
    "bold" => style.with_bold()
    "italic" => style.with_italic()
    "underline" => style.with_underline()
    "dimmed" => style.with_dimmed()
    "inverted" => style.with_inverted()
    "strikethrough" => style.with_strikethrough()
    _ if part.has_prefix("bg:") =>
      match parse_color(part[3:].to_string()) {
        Default => style
        color => style.with_bg(color)
      }
    _ =>
      match parse_color(part) {
        Default => style
        color => style.with_fg(color)
      }
  }
}
