///|
pub struct RubyModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RubyModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("ruby"),
) -> RubyModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="💎 "),
    detect_files: ["Gemfile", ".ruby-version"],
    detect_extensions: [".rb"],
  }
}

///|
pub fn RubyModule::from_config(config : @config.Config) -> RubyModule {
  RubyModule::new(config=config.get_module("ruby"))
}

///|
pub impl @ms.PromptModule for RubyModule with name(_self) -> String {
  "ruby"
}

///|
pub impl @ms.PromptModule for RubyModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  let has_env = not(@sys.get_env_var("RUBY_VERSION").unwrap_or("").is_empty()) ||
    not(@sys.get_env_var("RBENV_VERSION").unwrap_or("").is_empty())
  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Ruby project detected")
  }

  let output = @exec.exec_cmd("ruby", ["-v"])
  guard not(output.is_empty()) else { return Skipped("ruby not found") }

  let display = parse_ruby_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse ruby version")
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
fn parse_ruby_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() < 2 {
    return ""
  }

  let version_part = parts[1].to_string()

  match version_part.find("p") {
    Some(idx) => version_part[:idx].to_string()
    None => version_part
  }
}
