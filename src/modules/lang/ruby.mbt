///|
pub struct RubyModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_variables : Array[String]
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn RubyModule::default() -> RubyModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "💎 ",
    detect_variables: ["RUBY_VERSION", "RBENV_VERSION"],
    version_format: "v${raw}",
    detect_files: ["Gemfile", ".ruby-version"],
    detect_extensions: [".rb"],
    detect_folders: [],
  }
}

///|
pub fn RubyModule::from_table(table : @config.ModuleTable) -> RubyModule {
  let d = RubyModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_variables: table
    .get_string_array("detect_variables")
    .unwrap_or(d.detect_variables),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn RubyModule::from_config(config : @config.Config) -> RubyModule {
  match config.get_raw_module("ruby") {
    Some(table) => RubyModule::from_table(table)
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
    @exec.detect_project(
      ctx.cwd,
      self.detect_files,
      self.detect_extensions,
      folders=self.detect_folders,
    ) else {
    return Skipped("no Ruby project detected")
  }

  let output = @exec.exec_cmd("ruby", ["-v"])
  guard not(output.is_empty()) else { return Skipped("ruby not found") }

  let display = parse_ruby_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse ruby version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(display, self.version_format),
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
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() < 2 {
    return ""
  }

  let version_part = parts[1]

  match version_part.find("p") {
    Some(idx) => version_part[:idx].to_string()
    None => version_part
  }
}

///|
pub fn RubyModule::schema() -> @config.ModuleSchema {
  let d = RubyModule::default()
  {
    name: "ruby",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_variables",
        field_type: @config.FStringArray,
        default_value: d.detect_variables.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
