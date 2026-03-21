///|
pub struct ScalaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ScalaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("scala"),
) -> ScalaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🆂 "),
    detect_files: [".scalaenv", ".sbtenv", "build.sbt", ".metals"],
    detect_extensions: [".sbt", ".scala"],
  }
}

///|
pub fn ScalaModule::from_config(config : @config.Config) -> ScalaModule {
  ScalaModule::new(config=config.get_module("scala"))
}

///|
pub impl @ms.PromptModule for ScalaModule with name(_self) -> String {
  "scala"
}

///|
pub impl @ms.PromptModule for ScalaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Scala project detected")
  }

  let version = @exec.exec_cmd("scala-cli", ["version", "--scala"])
  if not(version.is_empty()) {
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
    return Output(@ms.ModuleOutput::new(segments))
  }

  let output = @exec.exec_cmd("scalac", ["-version"])
  guard not(output.is_empty()) else { return Skipped("scala not found") }

  let display = parse_scalac_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse scala version")
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
fn parse_scalac_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 4 {
    parts[3].to_string()
  } else {
    ""
  }
}
