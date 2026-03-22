///|
pub struct GolangModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  not_capable_style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GolangModule::default() -> GolangModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold cyan",
    not_capable_style: "bold red",
    symbol: "🐹 ",
    detect_files: [
      "go.mod", "go.sum", "go.work", "glide.yaml", "Gopkg.yml", "Gopkg.lock", ".go-version",
    ],
    detect_folders: ["Godeps"],
    detect_extensions: [".go"],
  }
}

///|
pub fn GolangModule::from_toml_table(
  table : @config.ModuleTable,
) -> GolangModule {
  let d = GolangModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    not_capable_style: @config.get_toml_string(table, "not_capable_style").unwrap_or(
      d.not_capable_style,
    ),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_folders: @config.get_toml_string_array(table, "detect_folders").unwrap_or(
      d.detect_folders,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn GolangModule::from_config(config : @config.Config) -> GolangModule {
  match config.get_raw_module("golang") {
    Some(table) => GolangModule::from_toml_table(table)
    None => GolangModule::default()
  }
}

///|
pub impl @ms.PromptModule for GolangModule with name(_self) -> String {
  "golang"
}

///|
pub impl @ms.PromptModule for GolangModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GolangModule with execute(
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
    return Skipped("no Go project detected")
  }

  let output = @exec.exec_cmd("go", ["version"])
  guard not(output.is_empty()) else { return Skipped("go not found") }

  let display = parse_go_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse go version")
  }

  let go_mod_version = get_go_mod_version(ctx.cwd)
  let in_range = check_go_version(display, go_mod_version)
  let active_style = if in_range { self.style } else { self.not_capable_style }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(display),
    "symbol": self.symbol,
    "style": active_style,
  }

  if not(go_mod_version.is_empty()) && not(in_range) {
    vars["mod_version"] = go_mod_version
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_go_version(output : String) -> String {
  let marker = "go version go"
  guard output.contains(marker) else { return output }

  let start = marker.length()
  match output[start:].to_string().find(" ") {
    Some(idx) => output[start:start + idx].to_string()
    None => output[start:].to_string()
  }
}

///|
fn get_go_mod_version(cwd : String) -> String {
  let path = cwd + "/go.mod"
  let content = @fs.read_file_to_string(path) catch { _ => return "" }
  let lines = content.split("\n").collect()

  for i = 0; i < lines.length(); i = i + 1 {
    let s = lines[i].to_string()
    if s.has_prefix("go ") {
      return trim_ws(s["go ".length():].to_string())
    }
  }

  ""
}

///|
fn check_go_version(installed : String, required : String) -> Bool {
  if required.is_empty() {
    return true
  }

  let inst_parts = installed.split(".").collect()
  let req_parts = required.split(".").collect()

  let inst_major = if inst_parts.length() >= 1 {
    parse_int_go(inst_parts[0].to_string())
  } else {
    0
  }
  let inst_minor = if inst_parts.length() >= 2 {
    parse_int_go(inst_parts[1].to_string())
  } else {
    0
  }

  let req_major = if req_parts.length() >= 1 {
    parse_int_go(req_parts[0].to_string())
  } else {
    0
  }
  let req_minor = if req_parts.length() >= 2 {
    parse_int_go(req_parts[1].to_string())
  } else {
    0
  }

  if inst_major != req_major {
    return inst_major > req_major
  }

  inst_minor >= req_minor
}

///|
fn parse_int_go(s : String) -> Int {
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
fn trim_ws(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  while start < end {
    let c = s[start].unsafe_to_char()
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      start += 1
    } else {
      break
    }
  }

  while end > start {
    let c = s[end - 1].unsafe_to_char()
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      end -= 1
    } else {
      break
    }
  }

  s[start:end].to_string()
}
