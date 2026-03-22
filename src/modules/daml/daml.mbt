///|
pub struct DamlModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DamlModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("daml"),
) -> DamlModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="Λ "),
    detect_files: ["daml.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn DamlModule::from_config(config : @config.Config) -> DamlModule {
  DamlModule::new(config=config.get_module("daml"))
}

///|
pub impl @ms.PromptModule for DamlModule with name(_self) -> String {
  "daml"
}

///|
pub impl @ms.PromptModule for DamlModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for DamlModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no DAML project detected")
  }

  let version = @sys.get_env_var("DAML_SDK_VERSION").unwrap_or("")

  let version = if version.is_empty() {
    let yaml_path = ctx.cwd + "/daml.yaml"
    let content = @fs.read_file_to_string(yaml_path) catch { _ => "" }
    parse_sdk_version(content)
  } else {
    version
  }

  guard not(version.is_empty()) else {
    return Skipped("could not determine DAML SDK version")
  }

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

///|
fn parse_sdk_version(content : String) -> String {
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("sdk-version:") {
      let parts = s.split(":").collect()
      if parts.length() >= 2 {
        return parts[1]
          .to_string()
          .trim_start(chars=" ")
          .trim_end(chars=" ")
          .to_string()
      }
    }
  }

  ""
}
