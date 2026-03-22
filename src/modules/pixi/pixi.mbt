///|
pub struct PixiModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  show_default_environment : Bool
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PixiModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("pixi"),
) -> PixiModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🧚 "),
    show_default_environment: config.get_prop(
      "show_default_environment",
      default="true",
    ) !=
    "false",
    detect_files: ["pixi.toml", "pixi.lock"],
    detect_extensions: [],
  }
}

///|
pub fn PixiModule::from_config(config : @config.Config) -> PixiModule {
  PixiModule::new(config=config.get_module("pixi"))
}

///|
pub impl @ms.PromptModule for PixiModule with name(_self) -> String {
  "pixi"
}

///|
pub impl @ms.PromptModule for PixiModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for PixiModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env_name = @sys.get_env_var("PIXI_ENVIRONMENT_NAME").unwrap_or("")
  let has_env = not(env_name.is_empty())

  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Pixi project detected")
  }

  let version = @exec.exec_cmd("pixi", ["--version"])
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(version.is_empty()) {
    let parts = version.split(" ").collect()
    let ver = if parts.length() >= 2 { parts[1].to_string() } else { version }
    vars["version"] = @exec.add_v_prefix(ver)
  }

  if has_env && (self.show_default_environment || env_name != "default") {
    vars["environment"] = env_name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
