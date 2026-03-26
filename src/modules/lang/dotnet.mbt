///|
pub struct DotnetModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  heuristic : Bool
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn DotnetModule::default() -> DotnetModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )(🎯 $tfm )]($style)",
    style: "blue bold",
    symbol: ".NET ",
    heuristic: true,
    version_format: "v${raw}",
    detect_files: [
      "global.json", "project.json", "Directory.Build.props", "Directory.Build.targets",
      "Packages.props",
    ],
    detect_extensions: [".csproj", ".fsproj", ".xproj"],
    detect_folders: [],
  }
}

///|
pub fn DotnetModule::from_table(table : @config.ModuleTable) -> DotnetModule {
  let d = DotnetModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    heuristic: table.get_bool("heuristic").unwrap_or(d.heuristic),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn DotnetModule::from_config(config : @config.Config) -> DotnetModule {
  match config.get_raw_module("dotnet") {
    Some(table) => DotnetModule::from_table(table)
    None => DotnetModule::default()
  }
}

///|
pub impl @ms.PromptModule for DotnetModule with name(_self) -> String {
  "dotnet"
}

///|
pub impl @ms.PromptModule for DotnetModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DotnetModule with execute(
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
    return Skipped("no .NET project detected")
  }

  let version = @exec.exec_cmd("dotnet", ["--version"])
  guard not(version.is_empty()) else { return Skipped("dotnet not found") }

  let vars : Map[String, String] = {
    "version": @exec.format_version(version, self.version_format),
    "symbol": self.symbol,
    "style": self.style,
  }

  let tfm = find_tfm(ctx.cwd, self.detect_extensions)
  if not(tfm.is_empty()) {
    vars["tfm"] = tfm
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn find_tfm(cwd : String, extensions : Array[String]) -> String {
  let entries = @fs.read_dir(cwd) catch { _ => return "" }

  entries
  .iter()
  .filter(fn(entry) { extensions.iter().any(fn(ext) { entry.has_suffix(ext) }) })
  .find_first(fn(entry) {
    let path = "\{cwd}/\{entry}"
    let content = @fs.read_file_to_string(path) catch { _ => return false }
    not(extract_tfm(content).is_empty())
  })
  .map(fn(entry) {
    let path = "\{cwd}/\{entry}"
    let content = @fs.read_file_to_string(path) catch { _ => return "" }
    extract_tfm(content)
  })
  .unwrap_or("")
}

///|
fn extract_tfm(content : String) -> String {
  ["<TargetFramework>", "<TargetFrameworks>"]
  .iter()
  .find_first(fn(tag) { content.find(tag) is Some(_) })
  .map(fn(tag) {
    match content.find(tag) {
      Some(idx) => {
        let start = idx + tag.length()
        let remaining = content[start:].to_string()
        match remaining.find("</") {
          Some(end_idx) => {
            let value = remaining[:end_idx].to_string()
            if not(value.is_empty()) {
              value
            } else {
              ""
            }
          }
          None => ""
        }
      }
      None => ""
    }
  })
  .unwrap_or("")
}

///|
pub fn DotnetModule::schema() -> @config.ModuleSchema {
  let d = DotnetModule::default()
  {
    name: "dotnet",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "heuristic",
        field_type: @config.FBool,
        default_value: d.heuristic.to_string(),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
