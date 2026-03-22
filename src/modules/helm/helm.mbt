///|
pub struct HelmModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn HelmModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("helm"),
) -> HelmModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⎈ "),
    detect_files: ["helmfile.yaml", "Chart.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn HelmModule::from_config(config : @config.Config) -> HelmModule {
  HelmModule::new(config=config.get_module("helm"))
}

///|
pub impl @ms.PromptModule for HelmModule with name(_self) -> String {
  "helm"
}

///|
pub impl @ms.PromptModule for HelmModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for HelmModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Helm project detected")
  }

  let output = @exec.exec_cmd("helm", ["version", "--short"])
  guard not(output.is_empty()) else { return Skipped("helm not found") }

  let display = parse_helm_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse helm version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(display),
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
fn parse_helm_version(output : String) -> String {
  let stripped = @exec.strip_v_prefix(output)
  let parts = stripped.split("+").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[0].to_string()
}
