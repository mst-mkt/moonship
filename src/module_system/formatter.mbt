///|
/// Parse format string and replace $variables and [text](style) patterns.
/// Delegates to AST-based parse + evaluate.
pub fn format_string(
  template : String,
  vars : Map[String, String],
  style : @terminal.Style,
) -> Array[Segment] {
  let ast = parse_format(template)
  evaluate(ast, vars, style)
}

///|
/// Evaluate an AST with string variables into styled segments.
fn evaluate(
  nodes : Array[FormatNode],
  vars : Map[String, String],
  default_style : @terminal.Style,
) -> Array[Segment] {
  let segments : Array[Segment] = []

  for node in nodes {
    match node {
      Text(t) =>
        segments.push(Segment::new(t, style=default_style))

      Escape(ch) =>
        segments.push(Segment::new(unescape(ch), style=default_style))

      Variable(name) =>
        match vars.get(name) {
          Some(val) =>
            // Variable values can contain inline styles like "[❯](bold green)"
            evaluate(parse_format(val), {}, default_style).each(fn(seg) {
              segments.push(seg)
            })
          None => ()
        }

      Styled(content_nodes, style_spec) => {
        let resolved_style = resolve_style(style_spec, vars)
        let text = nodes_to_text(content_nodes, vars)

        if not(text.is_empty()) {
          segments.push(Segment::new(text, style=resolved_style))
        }
      }
    }
  }

  segments
}

///|
/// Convert AST nodes to plain text with variable substitution (no styling).
fn nodes_to_text(
  nodes : Array[FormatNode],
  vars : Map[String, String],
) -> String {
  let buf = StringBuilder::new()

  for node in nodes {
    match node {
      Text(t) => buf.write_string(t)
      Escape(ch) => buf.write_string(unescape(ch))
      Variable(name) => buf.write_string(vars.get(name).unwrap_or(""))
      Styled(inner, _) => buf.write_string(nodes_to_text(inner, vars))
    }
  }

  buf.to_string()
}

///|
fn resolve_style(
  spec : String,
  vars : Map[String, String],
) -> @terminal.Style {
  let resolved = if spec.has_prefix("$") {
    vars.get(spec[1:].to_string()).unwrap_or(spec)
  } else {
    spec
  }

  @terminal.parse_style(resolved)
}

///|
/// Evaluate an AST with pre-rendered segment variables.
/// Used for top-level format composition where module outputs are segments.
pub fn evaluate_segments(
  nodes : Array[FormatNode],
  segment_vars : Map[String, Array[Segment]],
  default_style : @terminal.Style,
) -> Array[Segment] {
  let segments : Array[Segment] = []

  for node in nodes {
    match node {
      Text(t) =>
        segments.push(Segment::new(t, style=default_style))

      Escape(ch) =>
        segments.push(Segment::new(unescape(ch), style=default_style))

      Variable(name) =>
        match segment_vars.get(name) {
          Some(segs) => segs.each(fn(seg) { segments.push(seg) })
          None => ()
        }

      Styled(content_nodes, style_spec) => {
        let style = @terminal.parse_style(style_spec)
        let inner = evaluate_segments(content_nodes, segment_vars, style)
        inner.each(fn(seg) { segments.push(seg) })
      }
    }
  }

  segments
}

///|
/// Compose a format template with segment-level variables into a ModuleOutput.
pub fn compose_segments(
  template : String,
  segment_vars : Map[String, Array[Segment]],
) -> ModuleOutput {
  let ast = parse_format(template)
  let segs = evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
  )
  ModuleOutput::new(segs)
}

///|
/// Extract module names from a format string like "$directory$git_branch"
pub fn extract_module_names(format : String) -> Array[String] {
  collect_variable_names(parse_format(format))
}
