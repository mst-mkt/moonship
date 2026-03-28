///|
pub struct NodejsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  not_capable_style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn NodejsModule::default() -> NodejsModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    not_capable_style: "bold red",
    symbol: " ",
    version_format: "v${raw}",
    detect_files: ["package.json", ".node-version", ".nvmrc"],
    detect_folders: ["node_modules"],
    detect_extensions: [".js", ".mjs", ".cjs", ".ts", ".mts", ".cts"],
  }
}

///|
pub fn NodejsModule::from_table(table : @config.ModuleTable) -> NodejsModule {
  let d = NodejsModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    not_capable_style: table
    .get_string("not_capable_style")
    .unwrap_or(d.not_capable_style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn NodejsModule::from_config(config : @config.Config) -> NodejsModule {
  match config.get_raw_module("nodejs") {
    Some(table) => NodejsModule::from_table(table)
    None => NodejsModule::default()
  }
}

///|
pub impl @ms.PromptModule for NodejsModule with name(_self) -> String {
  "nodejs"
}

///|
pub impl @ms.PromptModule for NodejsModule with is_async(self) -> Bool {
  self.async_render
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
    "version": @exec.format_version(version, self.version_format),
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
  let content = @fs.read_file_to_string(cwd + "/package.json") catch {
    _ => return ""
  }

  guard content.find("\"engines\"") is Some(idx) else { return "" }

  let after_engines = content[idx + "\"engines\"".length():].to_string()

  guard after_engines.find("\"node\"") is Some(n_idx) else { return "" }

  let after_node = after_engines[n_idx + "\"node\"".length():].to_string()

  extract_json_value(after_node)
}

///|
fn extract_json_value(s : String) -> String {
  guard s.find(":") is Some(colon) else { return "" }

  let after_colon = s[colon + 1:].to_string()

  guard after_colon.find("\"") is Some(q_start) else { return "" }

  let after_quote = after_colon[q_start + 1:].to_string()

  guard after_quote.find("\"") is Some(q_end) else { return "" }

  after_quote[:q_end].to_string()
}

///|
fn check_version_satisfies(version : String, requirement : String) -> Bool {
  if requirement.is_empty() {
    return true
  }

  let ver = parse_semver(@exec.strip_v_prefix(version))

  requirement
  .split("||")
  .any(fn(range) { check_single_range(ver, trim_spaces(range.to_string())) })
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
  s.trim(chars=" ").to_string()
}

///|
fn parse_semver(s : String) -> (Int, Int, Int) {
  let parts = s.split(".").map(fn(p) { p.to_string() }).collect()
  let major = if parts.length() >= 1 {
    @exec.parse_leading_int(parts[0])
  } else {
    0
  }
  let minor = if parts.length() >= 2 {
    @exec.parse_leading_int(parts[1])
  } else {
    0
  }
  let patch = if parts.length() >= 3 {
    @exec.parse_leading_int(parts[2])
  } else {
    0
  }

  (major, minor, patch)
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

///|
pub fn NodejsModule::schema() -> @config.ModuleSchema {
  let d = NodejsModule::default()
  {
    name: "nodejs",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "not_capable_style",
        field_type: @config.FString,
        default_value: d.not_capable_style,
      },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
