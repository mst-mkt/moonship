///|
pub struct RubyModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RubyModule::default() -> RubyModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "💎 ",
    detect_files: ["Gemfile", ".ruby-version"],
    detect_extensions: [".rb"],
  }
}

///|
pub fn RubyModule::from_toml_table(table : @config.ModuleTable) -> RubyModule {
  let d = RubyModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn RubyModule::from_config(config : @config.Config) -> RubyModule {
  match config.get_raw_module("ruby") {
    Some(table) => RubyModule::from_toml_table(table)
    None => RubyModule::default()
  }
}

///|
pub impl @ms.PromptModule for RubyModule with name(_self) -> String {
  "ruby"
}

///|
pub impl @ms.PromptModule for RubyModule with is_async(self) -> Bool {
  self.async_render
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
