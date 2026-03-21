///|
pub(all) enum Color {
  Default
  Black
  Red
  Green
  Yellow
  Blue
  Purple
  Cyan
  White
  BrightBlack
  BrightRed
  BrightGreen
  BrightYellow
  BrightBlue
  BrightPurple
  BrightCyan
  BrightWhite
  Ansi256(Int)
  Hex(Int) // 0xRRGGBB
}

///|
pub(all) struct Style {
  fg : Color
  bg : Color
  bold : Bool
  italic : Bool
  underline : Bool
  blink : Bool
  dimmed : Bool
  hidden : Bool
  inverted : Bool
  strikethrough : Bool
}

///|
pub fn Style::default() -> Style {
  {
    fg: Default,
    bg: Default,
    bold: false,
    italic: false,
    underline: false,
    blink: false,
    dimmed: false,
    hidden: false,
    inverted: false,
    strikethrough: false,
  }
}

///|
pub fn Style::with_fg(self : Style, c : Color) -> Style {
  { ..self, fg: c }
}

///|
pub fn Style::with_bg(self : Style, c : Color) -> Style {
  { ..self, bg: c }
}

///|
pub fn Style::with_bold(self : Style) -> Style {
  { ..self, bold: true }
}

///|
pub fn Style::with_italic(self : Style) -> Style {
  { ..self, italic: true }
}

///|
pub fn Style::with_underline(self : Style) -> Style {
  { ..self, underline: true }
}

///|
pub fn Style::with_dimmed(self : Style) -> Style {
  { ..self, dimmed: true }
}

///|
pub fn Style::with_inverted(self : Style) -> Style {
  { ..self, inverted: true }
}

///|
pub fn Style::with_blink(self : Style) -> Style {
  { ..self, blink: true }
}

///|
pub fn Style::with_hidden(self : Style) -> Style {
  { ..self, hidden: true }
}

///|
pub fn Style::with_strikethrough(self : Style) -> Style {
  { ..self, strikethrough: true }
}
