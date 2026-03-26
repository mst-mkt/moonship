///|
pub struct GolangModule {
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
pub fn GolangModule::default() -> GolangModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold cyan",
    not_capable_style: "bold red",
    symbol: "🐹 ",
    version_format: "v${raw}",
    detect_files: [
      "go.mod", "go.sum", "go.work", "glide.yaml", "Gopkg.yml", "Gopkg.lock", ".go-version",
    ],
    detect_folders: ["Godeps"],
    detect_extensions: [".go"],
  }
}

///|
pub fn GolangModule::from_table(table : @config.ModuleTable) -> GolangModule {
  let d = GolangModule::default()
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
pub fn GolangModule::from_config(config : @config.Config) -> GolangModule {
  match config.get_raw_module("golang") {
    Some(table) => GolangModule::from_table(table)
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
    "version": @exec.format_version(display, self.version_format),
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

  content
  .split("\n")
  .map(fn(s) { s.to_string() })
  .find_first(fn(s) { s.has_prefix("go ") })
  .map(fn(s) { s["go ".length():].to_string().trim(chars=" \t\r\n").to_string() })
  .unwrap_or("")
}

///|
fn check_go_version(installed : String, required : String) -> Bool {
  if required.is_empty() {
    return true
  }

  let inst_parts = installed.split(".").map(fn(s) { s.to_string() }).collect()
  let req_parts = required.split(".").map(fn(s) { s.to_string() }).collect()

  let inst_major = if inst_parts.length() >= 1 {
    @exec.parse_leading_int(inst_parts[0])
  } else {
    0
  }
  let inst_minor = if inst_parts.length() >= 2 {
    @exec.parse_leading_int(inst_parts[1])
  } else {
    0
  }

  let req_major = if req_parts.length() >= 1 {
    @exec.parse_leading_int(req_parts[0])
  } else {
    0
  }
  let req_minor = if req_parts.length() >= 2 {
    @exec.parse_leading_int(req_parts[1])
  } else {
    0
  }

  if inst_major != req_major {
    return inst_major > req_major
  }

  inst_minor >= req_minor
}

///|
pub fn GolangModule::schema() -> @config.ModuleSchema {
  let d = GolangModule::default()
  {
    name: "golang",
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
    ],
  }
}
