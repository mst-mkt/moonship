///|
pub struct NodejsModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn NodejsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "nodejs",
  ),
) -> NodejsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
    detect_files: ["package.json", ".node-version", ".nvmrc"],
    detect_extensions: [".js", ".mjs", ".cjs", ".ts", ".mts", ".cts"],
  }
}

///|
pub fn NodejsModule::from_config(config : @config.Config) -> NodejsModule {
  NodejsModule::new(config=config.get_module("nodejs"))
}

///|
pub impl @ms.PromptModule for NodejsModule with name(_self) -> String {
  "nodejs"
}

///|
pub impl @ms.PromptModule for NodejsModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Node.js project detected")
  }

  let version = @exec.exec_cmd("node", ["--version"])
  guard not(version.is_empty()) else { return Skipped("node not found") }

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
