///|
test "extract names: multiple" {
  let names = @module_system.extract_module_names(
    "$directory$git_branch$character",
  )
  assert_eq(names, ["directory", "git_branch", "character"])
}

///|
test "extract names: empty" {
  assert_eq(@module_system.extract_module_names("").length(), 0)
}

///|
test "extract names: no $" {
  assert_eq(@module_system.extract_module_names("plain text").length(), 0)
}

///|
test "extract names: bare $" {
  assert_eq(@module_system.extract_module_names("$").length(), 0)
}

///|
test "format: variable" {
  let vars : Map[String, String] = { "name": "world" }
  let segs = @module_system.format_string(
    "hello $name!",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello world!")
}

///|
test "format: undefined var skipped" {
  let segs = @module_system.format_string(
    "hello $missing world",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello  world")
}

///|
test "format: [text](style)" {
  let vars : Map[String, String] = { "path": "/home" }
  let segs = @module_system.format_string(
    "[$path](bold red) ",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "/home")
  assert_true(segs[0].style.bold)
  assert_true(segs[0].style.fg is Red)
}

///|
test "format: [$var]($style)" {
  let vars : Map[String, String] = { "path": "test", "style": "bold green" }
  let segs = @module_system.format_string(
    "[$path]($style)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "test")
  assert_true(segs[0].style.bold)
  assert_true(segs[0].style.fg is Green)
}

///|
test "format: plain text only" {
  let segs = @module_system.format_string(
    "hello world",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 1)
  assert_eq(segs[0].text, "hello world")
}

///|
test "format: inline styled value" {
  let vars : Map[String, String] = { "symbol": "[❯](bold green)" }
  let segs = @module_system.format_string(
    "$symbol ",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "❯")
  assert_true(segs[0].style.bold)
  assert_true(segs[0].style.fg is Green)
}

///|
test "format: unclosed bracket" {
  let segs = @module_system.format_string(
    "[unclosed",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[")
}

///|
test "format: empty template" {
  let segs = @module_system.format_string("", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: bare $" {
  let segs = @module_system.format_string("$", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: nested brackets" {
  let segs = @module_system.format_string(
    "[[inner]](bold)",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[inner]")
}

///|
test "format: [text] without (style)" {
  let segs = @module_system.format_string(
    "[text] no style",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[")
}

///|
test "format: multiple segments" {
  let vars : Map[String, String] = { "a": "X", "b": "Y" }
  let segs = @module_system.format_string(
    "$a-$b",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "X-Y")
}

///|
test "format: inherits default style" {
  let style = @terminal.Style::default().with_bold()
  let segs = @module_system.format_string("text", {}, style)
  assert_true(segs[0].style.bold)
}

///|
test "render: basic" {
  let output = @module_system.ModuleOutput::new([
    @module_system.Segment::new("hello"),
    @module_system.Segment::new(" world"),
  ])
  assert_eq(output.render(), "hello world")
}

///|
test "render: with style" {
  let style = @terminal.Style::default().with_bold()
  let output = @module_system.ModuleOutput::new([
    @module_system.Segment::new("bold", style~),
  ])
  let rendered = output.render()
  assert_true(rendered.contains("\u001b["))
  assert_true(rendered.contains("bold"))
}

///|
test "render: empty" {
  let output = @module_system.ModuleOutput::new([])
  assert_eq(output.render(), "")
}

///|
test "format: escaped brackets" {
  let vars : Map[String, String] = { "x": "hello" }
  let segs = @module_system.format_string(
    "[\\[$x\\]](bold)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[hello]")
}

///|
test "format: escaped newline" {
  let segs = @module_system.format_string(
    "a\\nb",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\nb")
}

///|
test "format: escaped backslash" {
  let segs = @module_system.format_string(
    "a\\\\b",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\\b")
}
