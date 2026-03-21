///|
pub struct ElixirModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ElixirModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "elixir",
  ),
) -> ElixirModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="💧 "),
    detect_files: ["mix.exs"],
    detect_extensions: [],
  }
}

///|
pub fn ElixirModule::from_config(config : @config.Config) -> ElixirModule {
  ElixirModule::new(config=config.get_module("elixir"))
}

///|
pub impl @ms.PromptModule for ElixirModule with name(_self) -> String {
  "elixir"
}

///|
pub impl @ms.PromptModule for ElixirModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Elixir project detected")
  }

  let output = @exec.exec_cmd_full("elixir", ["--version"])
  guard not(output.is_empty()) else { return Skipped("elixir not found") }

  let (elixir_version, otp_version) = parse_elixir_version(output)
  guard not(elixir_version.is_empty()) else {
    return Skipped("could not parse elixir version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(elixir_version),
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(otp_version.is_empty()) {
    vars["otp_version"] = otp_version
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_elixir_version(output : String) -> (String, String) {
  let lines = output.split("\n").collect()
  let mut otp_version = ""
  let mut elixir_version = ""

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("Erlang/OTP") {
      let parts = s.split(" ").collect()
      if parts.length() >= 2 {
        otp_version = parts[1].to_string()
      }
    } else if s.has_prefix("Elixir") {
      let parts = s.split(" ").collect()
      if parts.length() >= 2 {
        elixir_version = parts[1].to_string()
      }
    }
  }

  (elixir_version, otp_version)
}
