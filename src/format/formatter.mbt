///|
/// Parse format string and replace $variables and [text](style) patterns.
/// Delegates to AST-based parse + evaluate.
pub fn format_string(
  template : String,
  vars : Map[String, String],
  style : @terminal.Style,
  palette? : Map[String, String] = @terminal.active_palette.val,
) -> Array[Segment] {
  let ast = parse_format(template)
  evaluate(ast, vars, style, palette)
}

///|
/// Evaluate an AST with string variables into styled segments.
fn evaluate(
  nodes : Array[FormatNode],
  vars : Map[String, String],
  default_style : @terminal.Style,
  palette : Map[String, String],
) -> Array[Segment] {
  evaluate_inner(nodes, vars, default_style, palette, reparse_vars=true)
}

///|
fn evaluate_inner(
  nodes : Array[FormatNode],
  vars : Map[String, String],
  default_style : @terminal.Style,
  palette : Map[String, String],
  reparse_vars~ : Bool,
) -> Array[Segment] {
  nodes
  .iter()
  .flat_map(fn(node) {
    match node {
      Text(t) => Iter::singleton(Segment::new(t, style=default_style))
      Escape(ch) =>
        Iter::singleton(Segment::new(unescape(ch), style=default_style))
      Variable(name) =>
        match vars.get(name) {
          Some(val) =>
            if reparse_vars {
              evaluate(parse_format(val), {}, default_style, palette).iter()
            } else if not(val.is_empty()) {
              Iter::singleton(Segment::new(val, style=default_style))
            } else {
              Iter::empty()
            }
          None => Iter::empty()
        }
      EnvVar(name) => {
        let val = @sys.get_env_var(name).unwrap_or("")
        if not(val.is_empty()) {
          Iter::singleton(Segment::new(val, style=default_style))
        } else {
          Iter::empty()
        }
      }
      Styled(content_nodes, style_spec) => {
        let resolved_style = resolve_style(style_spec, vars, palette)
        let segs = evaluate_inner(
          content_nodes,
          vars,
          resolved_style,
          palette,
          reparse_vars=false,
        )

        if segs.is_empty() {
          Iter::empty()
        } else {
          segs.iter()
        }
      }
      Conditional(content_nodes) =>
        if has_any_string_var(content_nodes, vars) {
          evaluate_inner(
            content_nodes,
            vars,
            default_style,
            palette,
            reparse_vars~,
          ).iter()
        } else {
          Iter::empty()
        }
    }
  })
  .collect()
}

///|
fn resolve_style(
  spec : String,
  vars : Map[String, String],
  palette : Map[String, String],
) -> @terminal.Style {
  let resolved = if spec.has_prefix("$") {
    vars.get(spec[1:].to_string()).unwrap_or(spec)
  } else {
    spec
  }

  @terminal.parse_style(resolved, palette~)
}

///|
/// Evaluate an AST with pre-rendered segment variables.
/// Used for top-level format composition where module outputs are segments.
pub fn evaluate_segments(
  nodes : Array[FormatNode],
  segment_vars : Map[String, Array[Segment]],
  default_style : @terminal.Style,
  palette? : Map[String, String] = @terminal.active_palette.val,
) -> Array[Segment] {
  nodes
  .iter()
  .flat_map(fn(node) {
    match node {
      Text(t) => Iter::singleton(Segment::new(t, style=default_style))
      Escape(ch) =>
        Iter::singleton(Segment::new(unescape(ch), style=default_style))
      Variable(name) =>
        match segment_vars.get(name) {
          Some(segs) => segs.iter()
          None => Iter::empty()
        }
      EnvVar(name) => {
        let val = @sys.get_env_var(name).unwrap_or("")
        if not(val.is_empty()) {
          Iter::singleton(Segment::new(val, style=default_style))
        } else {
          Iter::empty()
        }
      }
      Styled(content_nodes, style_spec) => {
        let style = @terminal.parse_style(style_spec, palette~)
        evaluate_segments(content_nodes, segment_vars, style, palette~).iter()
      }
      Conditional(content_nodes) =>
        if has_any_segment_var(content_nodes, segment_vars) {
          evaluate_segments(
            content_nodes,
            segment_vars,
            default_style,
            palette~,
          ).iter()
        } else {
          Iter::empty()
        }
    }
  })
  .collect()
}

///|
/// Compose a format template with segment-level variables into a ModuleOutput.
pub fn compose_segments(
  template : String,
  segment_vars : Map[String, Array[Segment]],
  palette? : Map[String, String] = @terminal.active_palette.val,
) -> ModuleOutput {
  let ast = parse_format(template)
  let segs = evaluate_segments(
    ast,
    segment_vars,
    @terminal.Style::default(),
    palette~,
  )
  ModuleOutput::new(segs)
}

///|
/// Extract module names from a format string like "$directory$git_branch"
pub fn extract_module_names(format : String) -> Array[String] {
  collect_variable_names(parse_format(format))
}

///|
fn has_any_string_var(
  nodes : Array[FormatNode],
  vars : Map[String, String],
) -> Bool {
  let has_var = collect_variable_names(nodes)
    .iter()
    .any(fn(name) {
      match vars.get(name) {
        Some(val) => not(val.is_empty())
        None => false
      }
    })
  has_var || has_any_env_var(nodes)
}

///|
fn has_any_segment_var(
  nodes : Array[FormatNode],
  vars : Map[String, Array[Segment]],
) -> Bool {
  let has_var = collect_variable_names(nodes)
    .iter()
    .any(fn(name) {
      match vars.get(name) {
        Some(segs) => not(segs.is_empty())
        None => false
      }
    })
  has_var || has_any_env_var(nodes)
}

///|
fn has_any_env_var(nodes : Array[FormatNode]) -> Bool {
  nodes
  .iter()
  .any(fn(node) {
    match node {
      EnvVar(name) => not(@sys.get_env_var(name).unwrap_or("").is_empty())
      Styled(content, _) | Conditional(content) => has_any_env_var(content)
      _ => false
    }
  })
}
