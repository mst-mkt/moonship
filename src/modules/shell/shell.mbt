///|
pub struct ShellModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  bash_indicator : String
  fish_indicator : String
  zsh_indicator : String
  unknown_indicator : String
}

///|
pub fn ShellModule::default() -> ShellModule {
  {
    disabled: true,
    async_render: false,
    format: "[$indicator]($style) ",
    style: "white bold",
    bash_indicator: "bsh",
    fish_indicator: "fsh",
    zsh_indicator: "zsh",
    unknown_indicator: "",
  }
}

///|
pub fn ShellModule::from_toml_table(table : @config.ModuleTable) -> ShellModule {
  let d = ShellModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    bash_indicator: @config.get_toml_string(table, "bash_indicator").unwrap_or(
      d.bash_indicator,
    ),
    fish_indicator: @config.get_toml_string(table, "fish_indicator").unwrap_or(
      d.fish_indicator,
    ),
    zsh_indicator: @config.get_toml_string(table, "zsh_indicator").unwrap_or(
      d.zsh_indicator,
    ),
    unknown_indicator: @config.get_toml_string(table, "unknown_indicator").unwrap_or(
      d.unknown_indicator,
    ),
  }
}

///|
pub fn ShellModule::from_config(config : @config.Config) -> ShellModule {
  match config.get_raw_module("shell") {
    Some(table) => ShellModule::from_toml_table(table)
    None => ShellModule::default()
  }
}

///|
pub impl @ms.PromptModule for ShellModule with name(_self) -> String {
  "shell"
}

///|
pub impl @ms.PromptModule for ShellModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for ShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let shell_name = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  guard not(shell_name.is_empty()) else { return Skipped("shell not detected") }

  let indicator = match shell_name {
    "bash" => self.bash_indicator
    "fish" => self.fish_indicator
    "zsh" => self.zsh_indicator
    _ => self.unknown_indicator
  }

  let vars : Map[String, String] = {
    "indicator": indicator,
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
pub fn ShellModule::schema() -> @config.ModuleSchema {
  let d = ShellModule::default()
  {
    name: "shell",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "bash_indicator",
        field_type: @config.FString,
        default_value: d.bash_indicator,
      },
      {
        name: "fish_indicator",
        field_type: @config.FString,
        default_value: d.fish_indicator,
      },
      {
        name: "zsh_indicator",
        field_type: @config.FString,
        default_value: d.zsh_indicator,
      },
      {
        name: "unknown_indicator",
        field_type: @config.FString,
        default_value: d.unknown_indicator,
      },
    ],
  }
}
