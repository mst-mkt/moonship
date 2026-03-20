///|
pub struct GolangModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GolangModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "golang",
  ),
) -> GolangModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐹 "),
    detect_files: [
      "go.mod", "go.sum", "go.work", "glide.yaml", "Gopkg.yml", "Gopkg.lock", ".go-version",
    ],
    detect_extensions: [".go"],
  }
}

///|
pub fn GolangModule::from_config(config : @config.Config) -> GolangModule {
  GolangModule::new(config=config.get_module("golang"))
}

///|
pub impl @ms.PromptModule for GolangModule with name(_self) -> String {
  "golang"
}

///|
pub impl @ms.PromptModule for GolangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Go project detected")
  }

  let output = @exec.exec_cmd("go", ["version"])
  guard not(output.is_empty()) else { return Skipped("go not found") }

  let display = parse_go_version(output)
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
fn parse_go_version(output : String) -> String {
  let marker = "go version go"
  guard output.contains(marker) else { return output }

  let start = marker.length()
  match output[start:].to_string().find(" ") {
    Some(idx) => output[start:start + idx].to_string()
    None => output[start:].to_string()
  }
}
