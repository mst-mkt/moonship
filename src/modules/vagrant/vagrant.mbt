///|
pub struct VagrantModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn VagrantModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "vagrant",
  ),
) -> VagrantModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⍱ "),
    detect_files: ["Vagrantfile"],
    detect_extensions: [],
  }
}

///|
pub fn VagrantModule::from_config(config : @config.Config) -> VagrantModule {
  VagrantModule::new(config=config.get_module("vagrant"))
}

///|
pub impl @ms.PromptModule for VagrantModule with name(_self) -> String {
  "vagrant"
}

///|
pub impl @ms.PromptModule for VagrantModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Vagrant project detected")
  }

  let output = @exec.exec_cmd("vagrant", ["--version"])
  guard not(output.is_empty()) else { return Skipped("vagrant not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 2 else {
    return Skipped("could not parse vagrant version")
  }

  let version = parts[1].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse vagrant version")
  }

  let vars : Map[String, String] = {
    "version": version,
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
