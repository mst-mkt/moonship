///|
pub struct EnvVarModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  variable : String
  default_value : String
}

///|
pub fn EnvVarModule::default() -> EnvVarModule {
  {
    disabled: false,
    async_render: false,
    format: "with [$symbol$env_value]($style) ",
    style: "black bold dimmed",
    symbol: "",
    variable: "",
    default_value: "",
  }
}

///|
pub fn EnvVarModule::from_toml_table(
  table : @config.ModuleTable,
) -> EnvVarModule {
  let d = EnvVarModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    variable: @config.get_toml_string(table, "variable").unwrap_or(d.variable),
    default_value: @config.get_toml_string(table, "default").unwrap_or(
      d.default_value,
    ),
  }
}

///|
pub fn EnvVarModule::from_config(config : @config.Config) -> EnvVarModule {
  match config.get_raw_module("env_var") {
    Some(table) => EnvVarModule::from_toml_table(table)
    None => EnvVarModule::default()
  }
}

///|
pub impl @ms.PromptModule for EnvVarModule with name(_self) -> String {
  "env_var"
}

///|
pub impl @ms.PromptModule for EnvVarModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for EnvVarModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard not(self.variable.is_empty()) else {
    return Skipped("no variable configured")
  }

  let env_value = @sys.get_env_var(self.variable).unwrap_or("")
  let display = if not(env_value.is_empty()) {
    env_value
  } else if not(self.default_value.is_empty()) {
    self.default_value
  } else {
    return Skipped("env var not set")
  }

  let vars : Map[String, String] = {
    "env_value": display,
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
pub fn EnvVarModule::schema() -> @config.ModuleSchema {
  let d = EnvVarModule::default()
  {
    name: "env_var",
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
        name: "variable",
        field_type: @config.FString,
        default_value: d.variable,
      },
      {
        name: "default_value",
        field_type: @config.FString,
        default_value: d.default_value,
      },
    ],
  }
}
