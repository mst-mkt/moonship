///|
pub enum FormatNode {
  Text(String)
  Escape(Char)
  Variable(String)
  EnvVar(String) // ${env:VAR_NAME}
  Styled(Array[FormatNode], String) // (content_nodes, style_spec)
  Conditional(Array[FormatNode]) // (content_nodes)
}

///|
/// Parse a format template string into an AST.
pub fn parse_format(template : String) -> Array[FormatNode] {
  let nodes : Array[FormatNode] = []
  let len = template.length()

  loop 0 {
    i =>
      if i >= len {
        break nodes
      } else {
        match char_at(template, i) {
          '\\' if i + 1 < len => {
            nodes.push(Escape(char_at(template, i + 1)))
            continue i + 2
          }
          '$' =>
            match parse_dollar(template, i) {
              Some((node, end)) => {
                nodes.push(node)
                continue end
              }
              None => continue i + 1
            }
          '[' =>
            match parse_styled_node(template, i) {
              Some((node, next_i)) => {
                nodes.push(node)
                continue next_i
              }
              None => {
                nodes.push(Text("["))
                continue i + 1
              }
            }
          '(' =>
            match find_matching(template, i, '(', ')') {
              Some(cp) => {
                let inner = template[i + 1:cp].to_string()
                let content_nodes = parse_format(inner)
                nodes.push(Conditional(content_nodes))
                continue cp + 1
              }
              None => {
                nodes.push(Text("("))
                continue i + 1
              }
            }
          '\\' => {
            // Trailing backslash at end of string (no char to escape)
            nodes.push(Text("\\"))
            continue i + 1
          }
          _ => {
            let end = scan_while(template, i, fn(c) {
              c != '$' && c != '[' && c != '\\' && c != '('
            })
            nodes.push(Text(template[i:end].to_string()))
            continue end
          }
        }
      }
  }
}

///|
fn parse_dollar(s : String, start : Int) -> (FormatNode, Int)? {
  let after = start + 1
  guard after < s.length() else { return None }

  // ${env:VAR_NAME}
  if char_at(s, after) == '{' {
    let env_prefix = "env:"
    let content_start = after + 1
    let close = scan_while(s, content_start, fn(c) { c != '}' })
    guard close < s.length() else { return None }

    let content = s[content_start:close].to_string()
    guard content.has_prefix(env_prefix) else { return None }

    let var_name = content[env_prefix.length():].to_string()
    return Some((EnvVar(var_name), close + 1))
  }

  // $variable
  let (name, end) = scan_ident(s, after)
  guard not(name.is_empty()) else { return None }

  Some((Variable(name), end))
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
  nodes
  .iter()
  .flat_map(fn(node) {
    match node {
      Variable(name) => Iter::singleton(name)
      Styled(content, _) => collect_variable_names(content).iter()
      Conditional(content) => collect_variable_names(content).iter()
      _ => Iter::empty()
    }
  })
  .collect()
}
