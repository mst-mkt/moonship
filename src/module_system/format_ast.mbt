///|
pub enum FormatNode {
  Text(String)
  Escape(Char)
  Variable(String)
  Styled(Array[FormatNode], String) // (content_nodes, style_spec)
  Conditional(Array[FormatNode]) // (content_nodes)
}

///|
/// Parse a format template string into an AST.
pub fn parse_format(template : String) -> Array[FormatNode] {
  let nodes : Array[FormatNode] = []
  let len = template.length()
  let mut i = 0

  while i < len {
    match char_at(template, i) {
      '\\' if i + 1 < len => {
        nodes.push(Escape(char_at(template, i + 1)))
        i += 2
      }
      '$' => {
        let (name, end) = scan_ident(template, i + 1)
        if not(name.is_empty()) {
          nodes.push(Variable(name))
        }
        i = end
      }
      '[' =>
        match parse_styled_node(template, i) {
          Some((node, next_i)) => {
            nodes.push(node)
            i = next_i
          }
          None => {
            nodes.push(Text("["))
            i += 1
          }
        }
      '(' =>
        match find_matching(template, i, '(', ')') {
          Some(cp) => {
            let inner = template[i + 1:cp].to_string()
            let content_nodes = parse_format(inner)
            nodes.push(Conditional(content_nodes))
            i = cp + 1
          }
          None => {
            nodes.push(Text("("))
            i += 1
          }
        }
      _ => {
        let end = scan_while(template, i, fn(c) {
          c != '$' && c != '[' && c != '\\' && c != '('
        })
        nodes.push(Text(template[i:end].to_string()))
        i = end
      }
    }
  }

  nodes
}

///|
fn parse_styled_node(s : String, start : Int) -> (FormatNode, Int)? {
  guard find_matching(s, start, '[', ']') is Some(cb) else { return None }

  let inner = s[start + 1:cb].to_string()
  let after_bracket = cb + 1

  guard after_bracket < s.length() && char_at(s, after_bracket) == '(' else {
    return None
  }

  let style_end = scan_while(s, after_bracket + 1, fn(c) { c != ')' })
  guard style_end < s.length() else { return None }

  let style_spec = s[after_bracket + 1:style_end].to_string()
  let content_nodes = parse_format(inner)

  Some((Styled(content_nodes, style_spec), style_end + 1))
}

///|
/// Collect all variable names referenced in the AST.
pub fn collect_variable_names(nodes : Array[FormatNode]) -> Array[String] {
  let names : Array[String] = []

  for node in nodes {
    match node {
      Variable(name) => names.push(name)
      Styled(content, _) =>
        collect_variable_names(content).each(fn(n) { names.push(n) })
      Conditional(content) =>
        collect_variable_names(content).each(fn(n) { names.push(n) })
      _ => ()
    }
  }

  names
}
