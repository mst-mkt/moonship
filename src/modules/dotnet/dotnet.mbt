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
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
