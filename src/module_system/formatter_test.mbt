///|
test "extract_module_names: multiple" {
  let names = @module_system.extract_module_names(
    "$directory$git_branch$character",
  )
  assert_eq(names, ["directory", "git_branch", "character"])
}

///|
test "extract_module_names: empty" {
  assert_eq(@module_system.extract_module_names("").length(), 0)
}

///|
test "extract_module_names: no $" {
  assert_eq(@module_system.extract_module_names("plain text").length(), 0)
}

///|
test "extract_module_names: bare $" {
  assert_eq(@module_system.extract_module_names("$").length(), 0)
}

///|
test "format_string: variable substitution" {
  let vars : Map[String, String] = { "name": "world" }
  let segs = @module_system.format_string(
    "hello $name!",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello world!")
}

///|
test "format_string: undefined var is skipped" {
  let segs = @module_system.format_string(
    "hello $missing world",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello  world")
}

///|
test "format_string: [text](style)" {
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
test "format_string: [$var]($style)" {
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
test "format_string: plain text only" {
  let segs = @module_system.format_string(
    "hello world",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 1)
  assert_eq(segs[0].text, "hello world")
}

///|
test "format_string: inline styled value" {
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
test "format_string: unclosed bracket" {
  let segs = @module_system.format_string(
    "[unclosed",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[")
}

///|
test "format_string: empty template" {
  let segs = @module_system.format_string("", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format_string: bare $" {
  let segs = @module_system.format_string("$", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format_string: nested brackets" {
  let segs = @module_system.format_string(
    "[[inner]](bold)",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[inner]")
}

///|
test "ModuleOutput::render" {
  let output = @module_system.ModuleOutput::new([
    @module_system.Segment::new("hello"),
    @module_system.Segment::new(" world"),
  ])
  assert_eq(output.render(), "hello world")
}

///|
test "ModuleOutput::render with style" {
  let style = @terminal.Style::default().with_bold()
  let output = @module_system.ModuleOutput::new([
    @module_system.Segment::new("bold", style~),
  ])
  let rendered = output.render()
  assert_true(rendered.contains("\u001b["))
  assert_true(rendered.contains("bold"))
}

///|
test "ModuleOutput::render empty" {
  let output = @module_system.ModuleOutput::new([])
  assert_eq(output.render(), "")
}

///|
test "format_string: [text] without (style)" {
  let segs = @module_system.format_string(
    "[text] no style",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[")
}

///|
test "format_string: multiple segments" {
  let vars : Map[String, String] = { "a": "X", "b": "Y" }
  let segs = @module_system.format_string(
    "$a-$b",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "X-Y")
}

///|
test "format_string: style inherits default" {
  let style = @terminal.Style::default().with_bold()
  let segs = @module_system.format_string("text", {}, style)
  assert_true(segs[0].style.bold)
}
