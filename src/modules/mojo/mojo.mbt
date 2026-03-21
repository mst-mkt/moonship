///|
pub struct MojoModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MojoModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("mojo"),
) -> MojoModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🔥 "),
    detect_files: [],
    detect_extensions: [".mojo", ".🔥"],
  }
}

///|
pub fn MojoModule::from_config(config : @config.Config) -> MojoModule {
  MojoModule::new(config=config.get_module("mojo"))
}

///|
pub impl @ms.PromptModule for MojoModule with name(_self) -> String {
  "mojo"
}

///|
pub impl @ms.PromptModule for MojoModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Mojo project detected")
  }

  let output = @exec.exec_cmd("mojo", ["--version"])
  guard not(output.is_empty()) else { return Skipped("mojo not found") }

  let display = parse_mojo_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse mojo version")
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
fn parse_mojo_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
