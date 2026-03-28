// --- extract_module_names ---

///|
test "extract names: multiple" {
  let names = @format.extract_module_names("$directory$git_branch$character")
  assert_eq(names, ["directory", "git_branch", "character"])
}

///|
test "extract names: empty" {
  assert_eq(@format.extract_module_names("").length(), 0)
}

///|
test "extract names: no $" {
  assert_eq(@format.extract_module_names("plain text").length(), 0)
}

///|
test "extract names: bare $" {
  assert_eq(@format.extract_module_names("$").length(), 0)
}

///|
test "extract names: inside styled block" {
  let names = @format.extract_module_names("[$path]($style)")
  // style spec is stored as raw string, not parsed as AST variable
  assert_eq(names, ["path"])
}

// --- format_string ---

///|
test "format: variable" {
  let vars : Map[String, String] = { "name": "world" }
  let segs = @format.format_string(
    "hello $name!",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello world!")
}

///|
test "format: undefined var skipped" {
  let segs = @format.format_string(
    "hello $missing world",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello  world")
}

///|
test "format: [text](style)" {
  let vars : Map[String, String] = { "path": "/home" }
  let segs = @format.format_string(
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
  let segs = @format.format_string(
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
  let segs = @format.format_string(
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
  let segs = @format.format_string("$symbol ", vars, @terminal.Style::default())
  assert_eq(segs[0].text, "❯")
  assert_true(segs[0].style.bold)
  assert_true(segs[0].style.fg is Green)
}

///|
test "format: unclosed bracket" {
  let segs = @format.format_string("[unclosed", {}, @terminal.Style::default())
  assert_eq(segs[0].text, "[")
}

///|
test "format: empty template" {
  let segs = @format.format_string("", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: bare $" {
  let segs = @format.format_string("$", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: nested brackets" {
  let segs = @format.format_string(
    "[[inner]](bold)",
    {},
    @terminal.Style::default(),
  )
  let text = segs.map(fn(s) { s.text }).join("")
  assert_eq(text, "[inner]")
  assert_true(segs[0].style.bold)
}

///|
test "format: nested styled block preserves inner style" {
  let vars : Map[String, String] = { "branch": "main", "style": "bg:yellow" }
  let segs = @format.format_string(
    "[[ $branch ](fg:red bg:yellow)]($style)",
    vars,
    @terminal.Style::default(),
  )
  let text = segs.map(fn(s) { s.text }).join("")
  assert_true(text.contains("main"))
  let branch_seg = segs.iter().find_first(fn(s) { s.text.contains("main") })
  guard branch_seg is Some(seg)
  assert_true(seg.style.fg is Red)
}

///|
test "format: nested styled block with special char variable" {
  let vars : Map[String, String] = { "stashed": "$", "style": "red bold" }
  let segs = @format.format_string(
    "[[$stashed]($style)](bold)",
    vars,
    @terminal.Style::default(),
  )
  let text = segs.map(fn(s) { s.text }).join("")
  assert_true(text.contains("$"))
}

///|
test "format: [text] without (style)" {
  let segs = @format.format_string(
    "[text] no style",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "[")
}

///|
test "format: multiple segments" {
  let vars : Map[String, String] = { "a": "X", "b": "Y" }
  let segs = @format.format_string("$a-$b", vars, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "X-Y")
}

///|
test "format: inherits default style" {
  let style = @terminal.Style::default().with_bold()
  let segs = @format.format_string("text", {}, style)
  assert_true(segs[0].style.bold)
}

///|
test "format: escaped brackets" {
  let vars : Map[String, String] = { "x": "hello" }
  let segs = @format.format_string(
    "[\\[$x\\]](bold)",
    vars,
    @terminal.Style::default(),
  )
  let text = segs.map(fn(s) { s.text }).join("")
  assert_eq(text, "[hello]")
  assert_true(segs[0].style.bold)
}

///|
test "format: escaped newline" {
  let segs = @format.format_string("a\\nb", {}, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\nb")
}

///|
test "format: escaped backslash" {
  let segs = @format.format_string("a\\\\b", {}, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\\b")
}

// --- render ---

///|
test "render: basic" {
  let output = @format.ModuleOutput::new([
    @format.Segment::new("hello"),
    @format.Segment::new(" world"),
  ])
  assert_eq(output.render(), "hello world")
}

///|
test "render: with style" {
  let style = @terminal.Style::default().with_bold()
  let output = @format.ModuleOutput::new([@format.Segment::new("bold", style~)])
  let rendered = output.render()
  assert_true(rendered.contains("\u001b["))
  assert_true(rendered.contains("bold"))
}

///|
test "render: empty" {
  let output = @format.ModuleOutput::new([])
  assert_eq(output.render(), "")
}

// --- parse_format (AST) ---

///|
test "parse_format: plain text" {
  let nodes = @format.parse_format("hello")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Text("hello"))
}

///|
test "parse_format: variable" {
  let nodes = @format.parse_format("$name")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Variable("name"))
}

///|
test "parse_format: escape" {
  let nodes = @format.parse_format("\\n")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Escape('n'))
}

///|
test "parse_format: styled" {
  let nodes = @format.parse_format("[hello](bold)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Styled(content, spec) else { fail("expected Styled") }
  assert_eq(spec, "bold")
  assert_eq(content.length(), 1)
  assert_true(content[0] is Text("hello"))
}

///|
test "parse_format: mixed" {
  let nodes = @format.parse_format("$a-[text](red)")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is Variable("a"))
  assert_true(nodes[1] is Text("-"))
  assert_true(nodes[2] is Styled(_))
}

///|
test "parse_format: nested variable in styled" {
  let nodes = @format.parse_format("[$path](bold)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Styled(content, _) else { fail("expected Styled") }
  assert_true(content[0] is Variable("path"))
}

// --- evaluate_segments ---

///|
test "evaluate_segments: variable substitution" {
  let bold = @terminal.Style::default().with_bold()
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "mod_a": [@format.Segment::new("hello", style=bold)],
  }
  let ast = @format.parse_format("$mod_a!")

  let segs = @format.evaluate_segments(
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
  let segment_vars : Map[String, Array[@format.Segment]] = {}
  let ast = @format.parse_format("$missing")

  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "evaluate_segments: escape preserved" {
  let segment_vars : Map[String, Array[@format.Segment]] = {}
  let ast = @format.parse_format("a\\nb")

  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "a\nb")
}

///|
test "evaluate_segments: multiple vars compose" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "a": [@format.Segment::new("X")],
    "b": [@format.Segment::new("Y")],
  }
  let ast = @format.parse_format("$a-$b")

  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "X-Y")
}

// --- compose_segments ---

///|
test "compose_segments: basic" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "dir": [@format.Segment::new("~/project")],
    "char": [@format.Segment::new("❯")],
  }

  let output = @format.compose_segments("$dir\\n$char", segment_vars)
  let rendered = output.render()
  assert_true(rendered.contains("~/project"))
  assert_true(rendered.contains("❯"))
  assert_true(rendered.contains("\n"))
}

///|
test "compose_segments: empty vars" {
  let segment_vars : Map[String, Array[@format.Segment]] = {}

  let output = @format.compose_segments("$missing", segment_vars)
  assert_eq(output.render(), "")
}

///|
test "compose_segments: preserves segment styles" {
  let bold_green = @terminal.Style::default().with_bold().with_fg(Green)
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "m": [@format.Segment::new("styled", style=bold_green)],
  }

  let output = @format.compose_segments("$m", segment_vars)
  assert_eq(output.segments[0].text, "styled")
  assert_true(output.segments[0].style.bold)
  assert_true(output.segments[0].style.fg is Green)
}

// --- ModuleResult ---

///|
test "ModuleResult::output: Output variant" {
  let out = @format.ModuleOutput::new([@format.Segment::new("test")])
  let result : @format.ModuleResult = Output(out)
  assert_true(result.output() is Some(_))
}

///|
test "ModuleResult::output: Skipped variant" {
  let result : @format.ModuleResult = Skipped("reason")
  assert_true(result.output() is None)
}

///|
test "ModuleResult::output: Disabled variant" {
  let result : @format.ModuleResult = Disabled
  assert_true(result.output() is None)
}

// --- collect_variable_names ---

///|
test "collect_variable_names: nested in styled" {
  let nodes = @format.parse_format("[$path]($style)")
  let names = @format.collect_variable_names(nodes)
  // style spec is stored as raw string, not parsed as variable
  assert_eq(names, ["path"])
}

///|
test "collect_variable_names: no variables" {
  let nodes = @format.parse_format("plain text")
  let names = @format.collect_variable_names(nodes)
  assert_eq(names.length(), 0)
}

// --- conditional format ---

///|
test "parse_format: conditional" {
  let nodes = @format.parse_format("($var)")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 1)
  assert_true(content[0] is Variable("var"))
}

///|
test "parse_format: conditional with styled content" {
  let nodes = @format.parse_format("([$status]($style))")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 1)
  assert_true(content[0] is Styled(_))
}

///|
test "parse_format: unclosed paren is text" {
  let nodes = @format.parse_format("(unclosed")
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] is Text("("))
}

///|
test "format: conditional shown when var non-empty" {
  let vars : Map[String, String] = { "x": "hello" }
  let segs = @format.format_string("($x)", vars, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello")
}

///|
test "format: conditional hidden when var empty" {
  let vars : Map[String, String] = { "x": "" }
  let segs = @format.format_string("($x)", vars, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional hidden when var missing" {
  let segs = @format.format_string("($x)", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional with literal and var" {
  let vars : Map[String, String] = { "branch": "main" }
  let segs = @format.format_string(
    "( on $branch)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), " on main")
}

///|
test "format: conditional hides literal when var empty" {
  let vars : Map[String, String] = { "branch": "" }
  let segs = @format.format_string(
    "( on $branch)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional with styled content" {
  let vars : Map[String, String] = { "status": "+!", "style": "bold red" }
  let segs = @format.format_string(
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
  let segs = @format.format_string("($a$b)", vars, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "yes")
}

///|
test "format: conditional hidden when all vars empty" {
  let vars : Map[String, String] = { "a": "", "b": "" }
  let segs = @format.format_string("($a$b)", vars, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional no variables always hidden" {
  let segs = @format.format_string(
    "(literal only)",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: conditional surrounded by text" {
  let vars : Map[String, String] = { "x": "val" }
  let segs = @format.format_string(
    "before($x)after",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "beforevalafter")
}

///|
test "format: conditional hidden keeps surrounding text" {
  let segs = @format.format_string(
    "before($x)after",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "beforeafter")
}

///|
test "evaluate_segments: conditional shown" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "mod": [@format.Segment::new("output")],
  }
  let ast = @format.parse_format("($mod)")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "output")
}

///|
test "evaluate_segments: conditional hidden when empty" {
  let segment_vars : Map[String, Array[@format.Segment]] = {}
  let ast = @format.parse_format("($mod)")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "collect_variable_names: inside conditional" {
  let nodes = @format.parse_format("([$status]($style))")
  let names = @format.collect_variable_names(nodes)
  assert_eq(names, ["status"])
}

// --- ${env:VAR} ---

///|
test "parse_format: env var" {
  let nodes = @format.parse_format("${env:HOME}")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is EnvVar("HOME"))
}

///|
test "parse_format: env var with surrounding text" {
  let nodes = @format.parse_format("dir=${env:HOME}!")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is Text("dir="))
  assert_true(nodes[1] is EnvVar("HOME"))
  assert_true(nodes[2] is Text("!"))
}

///|
test "parse_format: braced variable without env prefix" {
  let nodes = @format.parse_format("${my_var}")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Variable("my_var"))
}

///|
test "format: env var resolves" {
  // HOME is almost always set
  let segs = @format.format_string(
    "${env:HOME}",
    {},
    @terminal.Style::default(),
  )
  assert_true(segs.length() > 0)
  assert_true(segs[0].text.length() > 0)
}

///|
test "format: env var unset produces no output" {
  let segs = @format.format_string(
    "${env:MOONSHIP_TEST_NONEXISTENT_VAR}",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: env var in conditional shown when set" {
  // HOME is always set
  let segs = @format.format_string(
    "(home=${env:HOME})",
    {},
    @terminal.Style::default(),
  )
  assert_true(segs.map(fn(s) { s.text }).join("").contains("home="))
}

///|
test "format: env var in conditional hidden when unset" {
  let segs = @format.format_string(
    "(val=${env:MOONSHIP_TEST_NONEXISTENT_VAR})",
    {},
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "collect_variable_names: env var not included" {
  let nodes = @format.parse_format("$mod${env:HOME}")
  let names = @format.collect_variable_names(nodes)
  assert_eq(names, ["mod"])
}

// --- parse_format: additional edge cases ---

///|
test "parse_format: empty template" {
  let nodes = @format.parse_format("")
  assert_eq(nodes.length(), 0)
}

///|
test "parse_format: just text no special chars" {
  let nodes = @format.parse_format("hello world 123")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Text("hello world 123"))
}

///|
test "parse_format: escape backslash" {
  let nodes = @format.parse_format("\\\\")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Escape('\\'))
}

///|
test "parse_format: escape tab" {
  let nodes = @format.parse_format("\\t")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Escape('t'))
}

///|
test "parse_format: multiple escape sequences" {
  let nodes = @format.parse_format("\\n\\t")
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] is Escape('n'))
  assert_true(nodes[1] is Escape('t'))
}

///|
test "parse_format: variable with underscores and digits" {
  let nodes = @format.parse_format("$a_b_1")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Variable("a_b_1"))
}

///|
test "parse_format: env var empty name" {
  let nodes = @format.parse_format("${env:}")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is EnvVar(""))
}

///|
test "parse_format: env var unclosed brace" {
  let nodes = @format.parse_format("${env:missing")
  // unclosed brace means parse_dollar returns None, $ is skipped
  assert_true(nodes.length() > 0)
  // Should not produce an EnvVar node
  let has_env_var = nodes.iter().any(fn(n) { n is EnvVar(_) })
  assert_false(has_env_var)
}

///|
test "parse_format: bracket without style is Text" {
  let nodes = @format.parse_format("[text]")
  // [text] without following (style) produces Text("[") then Text("text]")
  assert_true(nodes.length() > 0)
  let has_styled = nodes.iter().any(fn(n) { n is Styled(_) })
  assert_false(has_styled)
}

///|
test "parse_format: empty conditional" {
  let nodes = @format.parse_format("()")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 0)
}

///|
test "parse_format: dollar at end" {
  let nodes = @format.parse_format("abc$")
  // $ at end: parse_dollar returns None, $ is skipped
  // "abc" is Text, then $ is consumed with no node produced
  assert_true(nodes.length() >= 1)
  assert_true(nodes[0] is Text("abc"))
}

///|
test "parse_format: mixed template" {
  let nodes = @format.parse_format("$a [styled](bold) (conditional $b) text")
  // Should contain: Variable("a"), Text(" "), Styled, Text(" "), Conditional, Text(" text")
  let has_variable = nodes.iter().any(fn(n) { n is Variable("a") })
  let has_styled = nodes.iter().any(fn(n) { n is Styled(_) })
  let has_conditional = nodes.iter().any(fn(n) { n is Conditional(_) })
  let has_text = nodes.iter().any(fn(n) { n is Text(_) })
  assert_true(has_variable)
  assert_true(has_styled)
  assert_true(has_conditional)
  assert_true(has_text)
}

///|
test "parse_format: nested conditional with styled content and var" {
  let nodes = @format.parse_format("([inner $var](style))")
  assert_eq(nodes.length(), 1)
  guard nodes[0] is Conditional(content) else { fail("expected Conditional") }
  assert_eq(content.length(), 1)
  guard content[0] is Styled(inner, spec) else { fail("expected Styled") }
  assert_eq(spec, "style")
  let has_var = inner.iter().any(fn(n) { n is Variable("var") })
  assert_true(has_var)
}

// --- edge cases: malformed input ---

///|
test "format: style spec with dollar var" {
  let vars : Map[String, String] = { "path": "/home", "style": "bold cyan" }
  let segs = @format.format_string(
    "[$path]($style)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "/home")
  assert_true(segs[0].style.bold)
}

///|
test "format: empty styled block" {
  let segs = @format.format_string("[](bold)", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: styled block with only empty var" {
  let vars : Map[String, String] = { "x": "" }
  let segs = @format.format_string(
    "[$x](bold)",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "format: deeply nested conditionals" {
  let vars : Map[String, String] = { "x": "val" }
  let segs = @format.format_string("((($x)))", vars, @terminal.Style::default())
  assert_true(segs.length() > 0)
}

///|
test "format: consecutive escaped chars" {
  let segs = @format.format_string("\\n\\t\\\\", {}, @terminal.Style::default())
  assert_eq(segs.map(fn(s) { s.text }).join(""), "\n\t\\")
}

///|
test "format: escape at end of string" {
  let segs = @format.format_string("abc\\", {}, @terminal.Style::default())
  assert_true(segs.length() >= 1)
}

///|
test "format: multiple dollar signs" {
  let segs = @format.format_string("$$name", {}, @terminal.Style::default())
  assert_eq(segs.length(), 0)
}

///|
test "format: styled with empty style spec" {
  let segs = @format.format_string("[text]()", {}, @terminal.Style::default())
  assert_eq(segs[0].text, "text")
}

///|
test "format: variable value contains format syntax" {
  let vars : Map[String, String] = { "x": "[nested](bold)" }
  let segs = @format.format_string("$x", vars, @terminal.Style::default())
  assert_eq(segs[0].text, "nested")
  assert_true(segs[0].style.bold)
}

///|
test "evaluate_segments: conditional with empty segment array" {
  let segment_vars : Map[String, Array[@format.Segment]] = { "mod": [] }
  let ast = @format.parse_format("($mod)")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.length(), 0)
}

///|
test "evaluate_segments: styled block inherits parent style" {
  let bold = @terminal.Style::default().with_bold()
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "x": [@format.Segment::new("hi", style=bold)],
  }
  let ast = @format.parse_format("[$x](bold red)")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "hi")
  assert_true(segs[0].style.bold)
}

// --- ${variable} and ${dotted.name} ---

///|
test "parse_format: unbraced dotted form splits at dot" {
  let nodes = @format.parse_format("$env_var.VIMSHELL")
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] is Variable("env_var"))
  assert_true(nodes[1] is Text(".VIMSHELL"))
}

///|
test "parse_format: braced dotted variable" {
  let nodes = @format.parse_format("${env_var.VIMSHELL}")
  assert_eq(nodes.length(), 1)
  assert_true(nodes[0] is Variable("env_var.VIMSHELL"))
}

///|
test "parse_format: braced dotted variable with surrounding text" {
  let nodes = @format.parse_format("before ${custom.my_cmd} after")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is Text("before "))
  assert_true(nodes[1] is Variable("custom.my_cmd"))
  assert_true(nodes[2] is Text(" after"))
}

///|
test "parse_format: multiple braced dotted variables" {
  let nodes = @format.parse_format("${env_var.A}${env_var.B}")
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] is Variable("env_var.A"))
  assert_true(nodes[1] is Variable("env_var.B"))
}

///|
test "parse_format: braced variable empty content" {
  let nodes = @format.parse_format("${}")
  // Empty content inside braces produces no variable
  let has_var = nodes.iter().any(fn(n) { n is Variable(_) })
  assert_false(has_var)
}

///|
test "parse_format: braced variable unclosed" {
  let nodes = @format.parse_format("${unclosed")
  let has_var = nodes.iter().any(fn(n) { n is Variable(_) })
  assert_false(has_var)
}

///|
test "parse_format: env var still works alongside braced variable" {
  let nodes = @format.parse_format("${env:HOME} ${my_var}")
  assert_eq(nodes.length(), 3)
  assert_true(nodes[0] is EnvVar("HOME"))
  assert_true(nodes[2] is Variable("my_var"))
}

///|
test "extract names: braced dotted variable" {
  let names = @format.extract_module_names("${env_var.VIMSHELL}")
  assert_eq(names, ["env_var.VIMSHELL"])
}

///|
test "extract names: mixed simple and braced dotted" {
  let names = @format.extract_module_names(
    "$directory ${env_var.VIMSHELL} $character",
  )
  assert_eq(names, ["directory", "env_var.VIMSHELL", "character"])
}

///|
test "format: braced dotted variable substitution" {
  let vars : Map[String, String] = { "env_var.HOME": "/home/user" }
  let segs = @format.format_string(
    "${env_var.HOME}",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "/home/user")
}

///|
test "format: braced simple variable substitution" {
  let vars : Map[String, String] = { "name": "world" }
  let segs = @format.format_string(
    "hello ${name}!",
    vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "hello world!")
}

///|
test "evaluate_segments: braced dotted variable" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "env_var.VIMSHELL": [@format.Segment::new("vim")],
  }
  let ast = @format.parse_format("${env_var.VIMSHELL}")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs[0].text, "vim")
}

///|
test "evaluate_segments: mixed simple and dotted variables" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "directory": [@format.Segment::new("~/project")],
    "env_var.VIMSHELL": [@format.Segment::new("vim")],
    "character": [@format.Segment::new("❯")],
  }
  let ast = @format.parse_format("$directory ${env_var.VIMSHELL} $character")
  let segs = @format.evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  assert_eq(segs.map(fn(s) { s.text }).join(""), "~/project vim ❯")
}

///|
test "compose_segments: dotted variable" {
  let segment_vars : Map[String, Array[@format.Segment]] = {
    "custom.hello": [@format.Segment::new("hi")],
  }
  let output = @format.compose_segments("${custom.hello}", segment_vars)
  assert_eq(output.render(), "hi")
}
