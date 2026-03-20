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
