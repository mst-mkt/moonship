// --- extract_module_names ---

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
test "extract names: inside styled block" {
  let names = @module_system.extract_module_names("[$path]($style)")
  // style spec is stored as raw string, not parsed as AST variable
  assert_eq(names, ["path"])
}

// --- format_string ---

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

// --- render ---

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

// --- parse_format (AST) ---

///|
test "parse_format: plain text" {
  let nodes = @module_system.parse_format("hello")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Text("hello"))
}

///|
test "parse_format: variable" {
  let nodes = @module_system.parse_format("$name")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Variable("name"))
}

///|
test "parse_format: escape" {
  let nodes = @module_system.parse_format("\\n")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Escape('n'))
}

///|
test "parse_format: styled" {
  let nodes = @module_system.parse_format("[hello](bold)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Styled(content, spec) else { fail("expected Styled") }
  assert_eq(spec, "bold")
  assert_eq(content.length(), 1)
  assert_true(content[0] is Text("hello"))
}

///|
test "parse_format: mixed" {
  let nodes = @module_system.parse_format("$a-[text](red)")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is Variable("a"))
  assert_true(nodes[1] is Text("-"))
  assert_true(nodes[2] is Styled(_))
}

///|
test "parse_format: nested variable in styled" {
  let nodes = @module_system.parse_format("[$path](bold)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Styled(content, _) else { fail("expected Styled") }
  assert_true(content[0] is Variable("path"))
}

// --- evaluate_segments ---

///|
test "evaluate_segments: variable substitution" {
  let bold = @terminal.Style::default().with_bold()
  let segment_vars : Map[String, Array[@module_system.Segment]] = {
    "mod_a": [@module_system.Segment::new("hello", style=bold)],
  }
  let ast = @module_system.parse_format("$mod_a!")

  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "hello")
  assert_true(segs[0].style.bold)
  assert_eq(segs[1].text, "!")
}

///|
test "evaluate_segments: missing variable skipped" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {}
  let ast = @module_system.parse_format("$missing")

  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "evaluate_segments: escape preserved" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {}
  let ast = @module_system.parse_format("a\\nb")

  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\nb")
}

///|
test "evaluate_segments: multiple vars compose" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {
    "a": [@module_system.Segment::new("X")],
    "b": [@module_system.Segment::new("Y")],
  }
  let ast = @module_system.parse_format("$a-$b")

  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "X-Y")
}

// --- compose_segments ---

///|
test "compose_segments: basic" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {
    "dir": [@module_system.Segment::new("~/project")],
    "char": [@module_system.Segment::new("❯")],
  }

  let output = @module_system.compose_segments("$dir\\n$char", segment_vars)
  let rendered = output.render()
  assert_true(rendered.contains("~/project"))
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("\n"))
}

///|
test "compose_segments: empty vars" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {}

  let output = @module_system.compose_segments("$missing", segment_vars)
  assert_eq(output.render(), "")
}

///|
test "compose_segments: preserves segment styles" {
  let bold_green = @terminal.Style::default().with_bold().with_fg(Green)
  let segment_vars : Map[String, Array[@module_system.Segment]] = {
    "m": [@module_system.Segment::new("styled", style=bold_green)],
  }

  let output = @module_system.compose_segments("$m", segment_vars)
  assert_eq(output.segments[0].text, "styled")
  assert_true(output.segments[0].style.bold)
  assert_true(output.segments[0].style.fg is Green)
}

// --- ModuleResult ---

///|
test "ModuleResult::output: Output variant" {
  let out = @module_system.ModuleOutput::new([
    @module_system.Segment::new("test"),
  ])
  let result : @module_system.ModuleResult = Output(out)
  assert_true(result.output() is Some(_))
}

///|
test "ModuleResult::output: Skipped variant" {
  let result : @module_system.ModuleResult = Skipped("reason")
  assert_true(result.output() is None)
}

///|
test "ModuleResult::output: Disabled variant" {
  let result : @module_system.ModuleResult = Disabled
  assert_true(result.output() is None)
}

// --- collect_variable_names ---

///|
test "collect_variable_names: nested in styled" {
  let nodes = @module_system.parse_format("[$path]($style)")
  let names = @module_system.collect_variable_names(nodes)
  // style spec is stored as raw string, not parsed as variable
  assert_eq(names, ["path"])
}

///|
test "collect_variable_names: no variables" {
  let nodes = @module_system.parse_format("plain text")
  let names = @module_system.collect_variable_names(nodes)
  assert_eq(names.length(), 0)
}

// --- conditional format ---

///|
test "parse_format: conditional" {
  let nodes = @module_system.parse_format("($var)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 1)
  assert_true(content[0] is Variable("var"))
}

///|
test "parse_format: conditional with styled content" {
  let nodes = @module_system.parse_format("([$status]($style))")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 1)
  assert_true(content[0] is Styled(_))
}

///|
test "parse_format: unclosed paren is text" {
  let nodes = @module_system.parse_format("(unclosed")
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] is Text("("))
}

///|
test "format: conditional shown when var non-empty" {
  let vars : Map[String, String] = { "x": "hello" }
  let segs = @module_system.format_string(
    "($x)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello")
}

///|
test "format: conditional hidden when var empty" {
  let vars : Map[String, String] = { "x": "" }
  let segs = @module_system.format_string(
    "($x)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional hidden when var missing" {
  let segs = @module_system.format_string(
    "($x)",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional with literal and var" {
  let vars : Map[String, String] = { "branch": "main" }
  let segs = @module_system.format_string(
    "( on $branch)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), " on main")
}

///|
test "format: conditional hides literal when var empty" {
  let vars : Map[String, String] = { "branch": "" }
  let segs = @module_system.format_string(
    "( on $branch)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional with styled content" {
  let vars : Map[String, String] = { "status": "+!", "style": "bold red" }
  let segs = @module_system.format_string(
    "([$status]($style))",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "+!")
  assert_true(segs[0].style.bold)
}

///|
test "format: conditional shown if any var non-empty" {
  let vars : Map[String, String] = { "a": "", "b": "yes" }
  let segs = @module_system.format_string(
    "($a$b)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "yes")
}

///|
test "format: conditional hidden when all vars empty" {
  let vars : Map[String, String] = { "a": "", "b": "" }
  let segs = @module_system.format_string(
    "($a$b)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional no variables always hidden" {
  let segs = @module_system.format_string(
    "(literal only)",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional surrounded by text" {
  let vars : Map[String, String] = { "x": "val" }
  let segs = @module_system.format_string(
    "before($x)after",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "beforevalafter")
}

///|
test "format: conditional hidden keeps surrounding text" {
  let segs = @module_system.format_string(
    "before($x)after",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "beforeafter")
}

///|
test "evaluate_segments: conditional shown" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {
    "mod": [@module_system.Segment::new("output")],
  }
  let ast = @module_system.parse_format("($mod)")
  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "output")
}

///|
test "evaluate_segments: conditional hidden when empty" {
  let segment_vars : Map[String, Array[@module_system.Segment]] = {}
  let ast = @module_system.parse_format("($mod)")
  let segs = @module_system.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "collect_variable_names: inside conditional" {
  let nodes = @module_system.parse_format("([$status]($style))")
  let names = @module_system.collect_variable_names(nodes)
  assert_eq(names, ["status"])
}

// --- ${env:VAR} ---

///|
test "parse_format: env var" {
  let nodes = @module_system.parse_format("${env:HOME}")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is EnvVar("HOME"))
}

///|
test "parse_format: env var with surrounding text" {
  let nodes = @module_system.parse_format("dir=${env:HOME}!")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is Text("dir="))
  assert_true(nodes[1] is EnvVar("HOME"))
  assert_true(nodes[2] is Text("!"))
}

///|
test "parse_format: invalid env syntax falls through" {
  let nodes = @module_system.parse_format("${invalid}")
  // ${invalid} doesn't have "env:" prefix, so $ is skipped, rest is text
  assert_true(nodes.length() > 0)
}

///|
test "format: env var resolves" {
  // HOME is almost always set
  let segs = @module_system.format_string(
    "${env:HOME}",
    {},
    @terminal.Style::default(),
  )
  assert_true(segs.length() > 0)
  assert_true(segs[0].text.length() > 0)
}

///|
test "format: env var unset produces no output" {
  let segs = @module_system.format_string(
    "${env:MOONSHIP_TEST_NONEXISTENT_VAR}",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: env var in conditional shown when set" {
  // HOME is always set
  let segs = @module_system.format_string(
    "(home=${env:HOME})",
    {},
    @terminal.Style::default(),
  )
  assert_true(segs.map(fn(s) { s.text }).join("").contains("home="))
}

///|
test "format: env var in conditional hidden when unset" {
  let segs = @module_system.format_string(
    "(val=${env:MOONSHIP_TEST_NONEXISTENT_VAR})",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "collect_variable_names: env var not included" {
  let nodes = @module_system.parse_format("$mod${env:HOME}")
  let names = @module_system.collect_variable_names(nodes)
  assert_eq(names, ["mod"])
}
