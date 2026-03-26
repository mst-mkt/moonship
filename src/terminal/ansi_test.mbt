///|
test "parse_style: bold + fg" {
  let style = @terminal.parse_style("bold green")
  assert_true(style.bold)
  assert_true(style.fg is Green)
}

///|
test "parse_style: bg" {
  let style = @terminal.parse_style("bold bg:red")
  assert_true(style.bold)
  assert_true(style.bg is Red)
}

///|
test "parse_style: multiple attrs" {
  let style = @terminal.parse_style("bold italic underline")
  assert_true(style.bold)
  assert_true(style.italic)
  assert_true(style.underline)
}

///|
test "parse_style: empty is default" {
  let style = @terminal.parse_style("")
  assert_eq(style.bold, false)
  assert_true(style.fg is Default)
}

///|
test "parse_style: dimmed" {
  let style = @terminal.parse_style("dimmed")
  assert_true(style.dimmed)
}

///|
test "parse_style: inverted" {
  let style = @terminal.parse_style("inverted")
  assert_true(style.inverted)
}

///|
test "parse_style: strikethrough" {
  let style = @terminal.parse_style("strikethrough")
  assert_true(style.strikethrough)
}

///|
test "parse_style: fg + bg + attr" {
  let style = @terminal.parse_style("bold red bg:blue")
  assert_true(style.bold)
  assert_true(style.fg is Red)
  assert_true(style.bg is Blue)
}

///|
test "parse_style: hex fg" {
  let style = @terminal.parse_style("#ff0000")
  assert_true(style.fg is Hex(0xff0000))
}

///|
test "parse_style: ansi256 fg" {
  let style = @terminal.parse_style("bold 200")
  assert_true(style.bold)
  assert_true(style.fg is Ansi256(200))
}

///|
test "parse_style: hex bg" {
  let style = @terminal.parse_style("bg:#00ff00")
  assert_true(style.bg is Hex(0x00ff00))
}

///|
test "parse_color: named" {
  assert_true(@terminal.parse_color("red") is Red)
  assert_true(@terminal.parse_color("cyan") is Cyan)
}

///|
test "parse_style: none resets" {
  let style = @terminal.parse_style("none")
  assert_true(style.fg is Default)
  assert_false(style.bold)
}

///|
test "parse_style: bold none resets" {
  let style = @terminal.parse_style("bold none")
  assert_false(style.bold)
}

///|
test "parse_style: none bold applies bold only" {
  let style = @terminal.parse_style("none bold")
  assert_true(style.bold)
  assert_true(style.fg is Default)
}

///|
test "parse_color: bright" {
  assert_true(@terminal.parse_color("bright-red") is BrightRed)
  assert_true(@terminal.parse_color("brightred") is BrightRed)
}

///|
test "parse_color: hex" {
  assert_true(@terminal.parse_color("#ff0000") is Hex(0xff0000))
  assert_true(@terminal.parse_color("#000000") is Hex(0))
}

///|
test "parse_color: hex without #" {
  assert_true(@terminal.parse_color("ff0000") is Hex(0xff0000))
}

///|
test "parse_color: ansi256" {
  assert_true(@terminal.parse_color("200") is Ansi256(200))
  assert_true(@terminal.parse_color("0") is Ansi256(0))
}

///|
test "parse_color: ansi256 boundary" {
  assert_true(@terminal.parse_color("255") is Ansi256(255))
  assert_true(@terminal.parse_color("256") is Default)
}

///|
test "parse_color: invalid is Default" {
  assert_true(@terminal.parse_color("invalid") is Default)
  assert_true(@terminal.parse_color("999") is Default)
}

///|
test "stylize: ansi codes applied" {
  let style = @terminal.Style::default().with_bold().with_fg(Red)
  let result = @terminal.stylize("hello", style)
  assert_true(result.contains("1;31"))
  assert_true(result.has_suffix("\u001b[0m"))
}

///|
test "stylize: empty string" {
  assert_eq(@terminal.stylize("", @terminal.Style::default()), "")
}

///|
test "stylize: no style" {
  assert_eq(@terminal.stylize("hello", @terminal.Style::default()), "hello")
}

///|
test "stylize: bg" {
  let style = @terminal.Style::default().with_bg(Blue)
  assert_true(@terminal.stylize("x", style).contains("44"))
}

///|
test "stylize: hex fg" {
  let style = @terminal.Style::default().with_fg(Hex(0xff8800))
  assert_true(@terminal.stylize("x", style).contains("38;2;255;136;0"))
}

///|
test "stylize: ansi256 fg" {
  let style = @terminal.Style::default().with_fg(Ansi256(42))
  assert_true(@terminal.stylize("x", style).contains("38;5;42"))
}

///|
test "stylize: ansi256 bg" {
  let style = @terminal.Style::default().with_bg(Ansi256(100))
  assert_true(@terminal.stylize("x", style).contains("48;5;100"))
}

///|
test "stylize: hex bg" {
  let style = @terminal.Style::default().with_bg(Hex(0x00ff00))
  assert_true(@terminal.stylize("x", style).contains("48;2;0;255;0"))
}

///|
test "stylize: bright color" {
  let style = @terminal.Style::default().with_fg(BrightCyan)
  assert_true(@terminal.stylize("x", style).contains("96"))
}

///|
test "parse_style: blink" {
  let style = @terminal.parse_style("blink")
  assert_true(style.blink)
}

///|
test "parse_style: hidden" {
  let style = @terminal.parse_style("hidden")
  assert_true(style.hidden)
}

///|
test "parse_style: case insensitive decorations" {
  let style = @terminal.parse_style("Bold Italic UNDERLINE")
  assert_true(style.bold)
  assert_true(style.italic)
  assert_true(style.underline)
}

///|
test "parse_color: case insensitive" {
  assert_true(@terminal.parse_color("Red") is Red)
  assert_true(@terminal.parse_color("BLUE") is Blue)
  assert_true(@terminal.parse_color("Bright-Red") is BrightRed)
  assert_true(@terminal.parse_color("BrightGreen") is BrightGreen)
}

///|
test "parse_style: case insensitive bg/fg prefix" {
  let style = @terminal.parse_style("BG:red FG:blue")
  assert_true(style.bg is Red)
  assert_true(style.fg is Blue)
}

///|
test "stylize: blink code" {
  let style = @terminal.Style::default().with_blink()
  let result = @terminal.stylize("x", style)
  assert_true(result.contains("\u001b[5m"))
}

///|
test "stylize: hidden code" {
  let style = @terminal.Style::default().with_hidden()
  let result = @terminal.stylize("x", style)
  assert_true(result.contains("\u001b[8m"))
}

///|
test "parse_style: blink and hidden with color" {
  let style = @terminal.parse_style("blink hidden red")
  assert_true(style.blink)
  assert_true(style.hidden)
  assert_true(style.fg is Red)
}

///|
test "parse_color: uppercase hex" {
  assert_true(@terminal.parse_color("#FF00AA") is Hex(0xFF00AA))
}

///|
test "stylize: fg + bg + multiple attrs" {
  let style = @terminal.Style::default()
    .with_bold()
    .with_italic()
    .with_fg(Green)
    .with_bg(Black)
  let result = @terminal.stylize("x", style)
  assert_true(result.contains("1"))
  assert_true(result.contains("3"))
  assert_true(result.contains("32"))
  assert_true(result.contains("40"))
}

// --- prev_fg / prev_bg ---

///|
test "parse_color: prev_fg" {
  assert_true(@terminal.parse_color("prev_fg") is PrevFg)
}

///|
test "parse_color: prev_bg" {
  assert_true(@terminal.parse_color("prev_bg") is PrevBg)
}

///|
test "parse_style: bg:prev_fg" {
  let style = @terminal.parse_style("bg:prev_fg")
  assert_true(style.bg is PrevFg)
}

///|
test "resolve_prev: fg from prev_fg" {
  let style = @terminal.Style::default().with_fg(PrevFg)
  let prev = @terminal.Style::default().with_fg(Red)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Red)
}

///|
test "resolve_prev: bg from prev_bg" {
  let style = @terminal.Style::default().with_bg(PrevBg)
  let prev = @terminal.Style::default().with_bg(Blue)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.bg is Blue)
}

///|
test "resolve_prev: bg from prev_fg (powerline)" {
  let style = @terminal.Style::default().with_bg(PrevFg)
  let prev = @terminal.Style::default().with_fg(Green)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.bg is Green)
}

///|
test "resolve_prev: fg from prev_bg" {
  let style = @terminal.Style::default().with_fg(PrevBg)
  let prev = @terminal.Style::default().with_bg(Cyan)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Cyan)
}

///|
test "resolve_prev: first segment defaults to no color" {
  let style = @terminal.Style::default().with_fg(PrevFg).with_bg(PrevBg)
  let prev = @terminal.Style::default()
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Default)
  assert_true(resolved.bg is Default)
}

// --- palette ---

///|
test "parse_color: palette lookup" {
  let palette : Map[String, String] = { "mustard": "#af8700" }
  assert_true(@terminal.parse_color("mustard", palette~) is Hex(_))
}

///|
test "parse_color: palette not found falls back" {
  let palette : Map[String, String] = { "mustard": "#af8700" }
  assert_true(@terminal.parse_color("unknown_color", palette~) is Default)
}

///|
test "parse_style: palette color in style" {
  let palette : Map[String, String] = { "sky": "#87ceeb" }
  let style = @terminal.parse_style("bold sky", palette~)
  assert_true(style.bold)
  assert_true(style.fg is Hex(_))
}

///|
test "parse_style: palette color in bg" {
  let palette : Map[String, String] = { "ocean": "blue" }
  let style = @terminal.parse_style("bg:ocean", palette~)
  assert_true(style.bg is Blue)
}

///|
test "resolve_prev: no prev colors unchanged" {
  let style = @terminal.Style::default().with_fg(Red).with_bg(Blue)
  let prev = @terminal.Style::default().with_fg(Green)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Red)
  assert_true(resolved.bg is Blue)
}

// --- parse_color edge cases ---

///|
test "parse_color: invalid hex returns Default" {
  assert_true(@terminal.parse_color("#GGGGGG", palette={}) is Default)
}

///|
test "parse_color: incomplete hex returns Default" {
  assert_true(@terminal.parse_color("#FF0", palette={}) is Default)
}

///|
test "parse_color: hex too long returns Default" {
  assert_true(@terminal.parse_color("#FF00FF00", palette={}) is Default)
}

///|
test "parse_color: empty string returns Default" {
  assert_true(@terminal.parse_color("", palette={}) is Default)
}

///|
test "parse_color: ANSI256 boundary 255 is valid" {
  assert_true(@terminal.parse_color("255", palette={}) is Ansi256(255))
}

///|
test "parse_color: ANSI256 boundary 256 is Default" {
  assert_true(@terminal.parse_color("256", palette={}) is Default)
}

///|
test "parse_color: negative number returns Default" {
  assert_true(@terminal.parse_color("-1", palette={}) is Default)
}

///|
test "parse_color: palette color with empty palette" {
  assert_true(@terminal.parse_color("my_color", palette={}) is Default)
}

///|
test "parse_color: palette lookup resolves named color" {
  let palette : Map[String, String] = { "primary": "red" }
  assert_true(@terminal.parse_color("primary", palette~) is Red)
}

///|
test "parse_color: palette lookup resolves hex" {
  let palette : Map[String, String] = { "accent": "#FF0000" }
  assert_true(@terminal.parse_color("accent", palette~) is Hex(0xFF0000))
}

// --- parse_style edge cases ---

///|
test "parse_style: empty string returns default" {
  let s = @terminal.parse_style("", palette={})
  assert_true(s.fg is Default)
  assert_false(s.bold)
}

///|
test "parse_style: none resets all" {
  let s = @terminal.parse_style("bold none", palette={})
  assert_false(s.bold)
}

///|
test "parse_style: multiple attributes combine" {
  let s = @terminal.parse_style("bold italic underline", palette={})
  assert_true(s.bold)
  assert_true(s.italic)
  assert_true(s.underline)
}

///|
test "parse_style: bg: prefix sets background" {
  let s = @terminal.parse_style("bg:red", palette={})
  assert_true(s.bg is Red)
  assert_true(s.fg is Default)
}

///|
test "parse_style: fg: prefix sets foreground" {
  let s = @terminal.parse_style("fg:blue", palette={})
  assert_true(s.fg is Blue)
}

///|
test "parse_style: bg: with hex color" {
  let s = @terminal.parse_style("bg:#FF0000", palette={})
  assert_true(s.bg is Hex(_))
}

///|
test "parse_style: unknown attribute treated as color" {
  let s = @terminal.parse_style("red", palette={})
  assert_true(s.fg is Red)
}

///|
test "parse_style: case insensitive" {
  let s = @terminal.parse_style("BOLD RED", palette={})
  assert_true(s.bold)
  assert_true(s.fg is Red)
}

// --- stylize edge cases ---

///|
test "stylize: empty text returns empty" {
  let s = @terminal.Style::default().with_bold()
  assert_eq(@terminal.stylize("", s), "")
}

///|
test "stylize: default style returns text unchanged" {
  assert_eq(@terminal.stylize("hello", @terminal.Style::default()), "hello")
}

// --- resolve_prev edge cases ---

///|
test "resolve_prev: PrevFg with default prev uses default" {
  let style = @terminal.Style::default().with_fg(PrevFg)
  let prev = @terminal.Style::default()
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Default)
}

///|
test "resolve_prev: PrevBg resolves to prev bg color" {
  let style = @terminal.Style::default().with_fg(PrevBg)
  let prev = @terminal.Style::default().with_bg(Blue)
  let resolved = style.resolve_prev(prev)
  assert_true(resolved.fg is Blue)
}
