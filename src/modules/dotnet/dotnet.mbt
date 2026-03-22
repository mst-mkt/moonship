///|
pub struct DotnetModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DotnetModule::default() -> DotnetModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )(🎯 $tfm )]($style)",
    style: "blue bold",
    symbol: ".NET ",
    detect_files: [
      "global.json", "project.json", "Directory.Build.props", "Directory.Build.targets",
      "Packages.props",
    ],
    detect_extensions: [".csproj", ".fsproj", ".xproj"],
  }
}

///|
pub fn DotnetModule::from_toml_table(
  table : @config.ModuleTable,
) -> DotnetModule {
  let d = DotnetModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn DotnetModule::from_config(config : @config.Config) -> DotnetModule {
  match config.get_raw_module("dotnet") {
    Some(table) => DotnetModule::from_toml_table(table)
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
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no .NET project detected")
  }

  let version = @exec.exec_cmd("dotnet", ["--version"])
  guard not(version.is_empty()) else { return Skipped("dotnet not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
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

  for entry in entries {
    for ext in extensions {
      if entry.has_suffix(ext) {
        let path = cwd + "/" + entry
        let content = @fs.read_file_to_string(path) catch { _ => continue }
        let tfm = extract_tfm(content)
        if not(tfm.is_empty()) {
          return tfm
        }
      }
    }
  }

  ""
}

///|
fn extract_tfm(content : String) -> String {
  let tags = ["<TargetFramework>", "<TargetFrameworks>"]

  for tag in tags {
    match content.find(tag) {
      Some(idx) => {
        let start = idx + tag.length()
        let remaining = content[start:].to_string()
        let end_tag = "</"

        match remaining.find(end_tag) {
          Some(end_idx) => {
            let value = remaining[:end_idx].to_string()
            if not(value.is_empty()) {
              return value
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }

  ""
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
    ],
  }
}
