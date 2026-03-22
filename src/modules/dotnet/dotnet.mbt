///|
pub struct DotnetModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DotnetModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "dotnet",
  ),
) -> DotnetModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=".NET "),
    detect_files: [
      "global.json", "project.json", "Directory.Build.props", "Directory.Build.targets",
      "Packages.props",
    ],
    detect_extensions: [".csproj", ".fsproj", ".xproj"],
  }
}

///|
pub fn DotnetModule::from_config(config : @config.Config) -> DotnetModule {
  DotnetModule::new(config=config.get_module("dotnet"))
}

///|
pub impl @ms.PromptModule for DotnetModule with name(_self) -> String {
  "dotnet"
}

///|
pub impl @ms.PromptModule for DotnetModule with is_async(_self) -> Bool {
  false
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
