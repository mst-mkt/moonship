///|
pub struct HaxeModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn HaxeModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("haxe"),
) -> HaxeModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⌘ "),
    detect_files: ["haxelib.json", "hxformat.json", ".haxerc"],
    detect_folders: [".haxelib", "haxe_libraries"],
    detect_extensions: [".hx", ".hxml"],
  }
}

///|
pub fn HaxeModule::from_config(config : @config.Config) -> HaxeModule {
  HaxeModule::new(config=config.get_module("haxe"))
}

///|
pub impl @ms.PromptModule for HaxeModule with name(_self) -> String {
  "haxe"
}

///|
pub impl @ms.PromptModule for HaxeModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no Haxe project detected")
  }

  let version = @exec.exec_cmd("haxe", ["--version"])
  guard not(version.is_empty()) else { return Skipped("haxe not found") }

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
