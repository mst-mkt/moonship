///|
pub struct OpaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn OpaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("opa"),
) -> OpaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🪖 "),
    detect_files: [],
    detect_extensions: [".rego"],
  }
}

///|
pub fn OpaModule::from_config(config : @config.Config) -> OpaModule {
  OpaModule::new(config=config.get_module("opa"))
}

///|
pub impl @ms.PromptModule for OpaModule with name(_self) -> String {
  "opa"
}

///|
pub impl @ms.PromptModule for OpaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no OPA project detected")
  }

  let output = @exec.exec_cmd("opa", ["version"])
  guard not(output.is_empty()) else { return Skipped("opa not found") }

  let display = parse_opa_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse opa version")
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
fn parse_opa_version(output : String) -> String {
  let lines = output.split("\n").collect()
  if lines.length() == 0 {
    return ""
  }

  let first_line = lines[0].to_string()
  let parts = first_line.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
