///|
pub struct DenoModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DenoModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("deno"),
) -> DenoModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🦕 "),
    detect_files: [
      "deno.json", "deno.jsonc", "deno.lock", "mod.ts", "deps.ts", "mod.js", "deps.js",
    ],
    detect_extensions: [],
  }
}

///|
pub fn DenoModule::from_config(config : @config.Config) -> DenoModule {
  DenoModule::new(config=config.get_module("deno"))
}

///|
pub impl @ms.PromptModule for DenoModule with name(_self) -> String {
  "deno"
}

///|
pub impl @ms.PromptModule for DenoModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Deno project detected")
  }

  let output = @exec.exec_cmd("deno", ["-V"])
  guard not(output.is_empty()) else { return Skipped("deno not found") }

  let display = parse_deno_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse deno version")
  }

  let vars : Map[String, String] = {
    "version": display,
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
fn parse_deno_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
  } else {
    ""
  }
}
