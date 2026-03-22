///|
pub struct NodejsModule {
  disabled : Bool
  format : String
  style : String
  not_capable_style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn NodejsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "nodejs",
  ),
) -> NodejsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    not_capable_style: config.get_prop("not_capable_style", default="bold red"),
    symbol: config.get_prop("symbol", default=" "),
    detect_files: ["package.json", ".node-version", ".nvmrc"],
    detect_folders: ["node_modules"],
    detect_extensions: [".js", ".mjs", ".cjs", ".ts", ".mts", ".cts"],
  }
}

///|
pub fn NodejsModule::from_config(config : @config.Config) -> NodejsModule {
  NodejsModule::new(config=config.get_module("nodejs"))
}

///|
pub impl @ms.PromptModule for NodejsModule with name(_self) -> String {
  "nodejs"
}

///|
pub impl @ms.PromptModule for NodejsModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for NodejsModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no Node.js project detected")
  }

  let version = @exec.exec_cmd("node", ["--version"])
  guard not(version.is_empty()) else { return Skipped("node not found") }

  let engines_req = get_engines_version(ctx.cwd)
  let in_range = check_version_satisfies(version, engines_req)
  let active_style = if in_range { self.style } else { self.not_capable_style }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
    "symbol": self.symbol,
    "style": active_style,
  }

  if not(engines_req.is_empty()) && not(in_range) {
    vars["engines_version"] = engines_req
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn get_engines_version(cwd : String) -> String {
  let path = cwd + "/package.json"
  let content = @fs.read_file_to_string(path) catch { _ => return "" }

  let engines_key = "\"engines\""
  match content.find(engines_key) {
    None => ""
    Some(idx) => {
      let after = content[idx + engines_key.length():].to_string()

      let node_key = "\"node\""
      match after.find(node_key) {
        None => ""
        Some(n_idx) => {
          let after_node = after[n_idx + node_key.length():].to_string()
          extract_json_string(after_node)
        }
      }
    }
  }
}

///|
fn extract_json_string(s : String) -> String {
  let colon = match s.find(":") {
    Some(p) => p
    None => return ""
  }

  let after_colon = s[colon + 1:].to_string()
  let quote_start = match after_colon.find("\"") {
    Some(p) => p
    None => return ""
  }

  let after_quote = after_colon[quote_start + 1:].to_string()
  let quote_end = match after_quote.find("\"") {
    Some(p) => p
    None => return ""
  }

  after_quote[:quote_end].to_string()
}

///|
fn check_version_satisfies(version : String, requirement : String) -> Bool {
  if requirement.is_empty() {
    return true
  }

  let ranges = requirement.split("||").collect()
  let ver = parse_semver(@exec.strip_v_prefix(version))

  for range in ranges {
    let trimmed = trim_spaces(range.to_string())
    if check_single_range(ver, trimmed) {
      return true
    }
  }

  ranges.length() == 0
}

///|
fn check_single_range(ver : (Int, Int, Int), requirement : String) -> Bool {
  let (op, req_ver) = parse_requirement(trim_spaces(requirement))

  match op {
    ">=" => semver_cmp(ver, req_ver) >= 0
    ">" => semver_cmp(ver, req_ver) > 0
    "<=" => semver_cmp(ver, req_ver) <= 0
    "<" => semver_cmp(ver, req_ver) < 0
    "=" | "==" => semver_cmp(ver, req_ver) == 0
    "^" => caret_satisfies(ver, req_ver)
    "~" =>
      ver.0 == req_ver.0 && ver.1 == req_ver.1 && semver_cmp(ver, req_ver) >= 0
    _ => true
  }
}

///|
fn caret_satisfies(ver : (Int, Int, Int), req : (Int, Int, Int)) -> Bool {
  if semver_cmp(ver, req) < 0 {
    return false
  }

  if req.0 > 0 {
    ver.0 == req.0
  } else if req.1 > 0 {
    ver.0 == 0 && ver.1 == req.1
  } else {
    ver.0 == 0 && ver.1 == 0 && ver.2 == req.2
  }
}

///|
fn trim_spaces(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  while start < end && s[start].unsafe_to_char() == ' ' {
    start += 1
  }

  while end > start && s[end - 1].unsafe_to_char() == ' ' {
    end -= 1
  }

  s[start:end].to_string()
}

///|
fn parse_semver(s : String) -> (Int, Int, Int) {
  let parts = s.split(".").collect()
  let major = if parts.length() >= 1 {
    parse_int_simple(parts[0].to_string())
  } else {
    0
  }
  let minor = if parts.length() >= 2 {
    parse_int_simple(parts[1].to_string())
  } else {
    0
  }
  let patch = if parts.length() >= 3 {
    parse_int_simple(parts[2].to_string())
  } else {
    0
  }

  (major, minor, patch)
}

///|
fn parse_int_simple(s : String) -> Int {
  let mut result = 0

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      break
    }
  }

  result
}

///|
fn parse_requirement(s : String) -> (String, (Int, Int, Int)) {
  let (op, rest) = if s.has_prefix(">=") {
    (">=", s[2:].to_string())
  } else if s.has_prefix("<=") {
    ("<=", s[2:].to_string())
  } else if s.has_prefix("==") {
    ("==", s[2:].to_string())
  } else if s.has_prefix("^") {
    ("^", s[1:].to_string())
  } else if s.has_prefix("~") {
    ("~", s[1:].to_string())
  } else if s.has_prefix(">") {
    (">", s[1:].to_string())
  } else if s.has_prefix("<") {
    ("<", s[1:].to_string())
  } else if s.has_prefix("=") {
    ("=", s[1:].to_string())
  } else {
    ("^", s)
  }

  (op, parse_semver(trim_spaces(rest)))
}

///|
fn semver_cmp(a : (Int, Int, Int), b : (Int, Int, Int)) -> Int {
  if a.0 != b.0 {
    return a.0 - b.0
  }

  if a.1 != b.1 {
    return a.1 - b.1
  }

  a.2 - b.2
}
