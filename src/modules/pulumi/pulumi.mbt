///|
pub struct PulumiModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PulumiModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "pulumi",
  ),
) -> PulumiModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
    detect_files: ["Pulumi.yaml", "Pulumi.yml"],
    detect_extensions: [],
  }
}

///|
pub fn PulumiModule::from_config(config : @config.Config) -> PulumiModule {
  PulumiModule::new(config=config.get_module("pulumi"))
}

///|
pub impl @ms.PromptModule for PulumiModule with name(_self) -> String {
  "pulumi"
}

///|
pub impl @ms.PromptModule for PulumiModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Pulumi project detected")
  }

  let stack_output = @exec.exec_cmd("pulumi", [
    "stack", "--non-interactive", "--show-name",
  ])
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(stack_output.is_empty()) {
    vars["stack"] = stack_output
  }

  let version = @exec.exec_cmd("pulumi", ["version"])
  if not(version.is_empty()) {
    vars["version"] = @exec.add_v_prefix(@exec.strip_v_prefix(version))
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
