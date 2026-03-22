///|
pub struct RakuModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RakuModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("raku"),
) -> RakuModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🦋 "),
    detect_files: ["META6.json"],
    detect_extensions: [".p6", ".pm6", ".pod6", ".raku", ".rakumod"],
  }
}

///|
pub fn RakuModule::from_config(config : @config.Config) -> RakuModule {
  RakuModule::new(config=config.get_module("raku"))
}

///|
pub impl @ms.PromptModule for RakuModule with name(_self) -> String {
  "raku"
}

///|
pub impl @ms.PromptModule for RakuModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for RakuModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Raku project detected")
  }

  let output = @exec.exec_cmd_full("raku", ["--version"])
  guard not(output.is_empty()) else { return Skipped("raku not found") }

  let (version, vm_version) = parse_raku_version(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse raku version")
  }

  let vars : Map[String, String] = {
    "version": version,
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(vm_version.is_empty()) {
    vars["vm_version"] = vm_version
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_raku_version(output : String) -> (String, String) {
  let lines = output.split("\n").collect()
  let mut version = ""
  let mut vm_version = ""

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("This is Rakudo") {
      let parts = s.split(" ").collect()
      if parts.length() >= 5 {
        version = parts[4].to_string()
      }
    } else if s.contains("MoarVM version") {
      let parts = s.split(" ").collect()

      for i = 0; i < parts.length(); i = i + 1 {
        if parts[i].to_string() == "version" && i + 1 < parts.length() {
          vm_version = parts[i + 1].to_string()
          break
        }
      }
    }
  }

  (version, vm_version)
}
