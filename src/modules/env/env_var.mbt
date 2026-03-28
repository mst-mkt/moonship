///|
pub struct EnvVarModule {
  module_name : String
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
    module_name: "env_var",
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
pub fn EnvVarModule::from_table(
  table : @config.ModuleTable,
  module_name? : String = "env_var",
) -> EnvVarModule {
  let d = EnvVarModule::default()
  {
    module_name,
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    variable: table.get_string("variable").unwrap_or(d.variable),
    default_value: table.get_string("default").unwrap_or(d.default_value),
  }
}

///|
pub fn EnvVarModule::from_config(config : @config.Config) -> EnvVarModule {
  match config.get_raw_module("env_var") {
    Some(table) => EnvVarModule::from_table(table)
    None => EnvVarModule::default()
  }
}

///|
pub fn EnvVarModule::from_named_config(
  config : @config.Config,
  instance_name : String,
) -> EnvVarModule {
  let module_name = "env_var.\{instance_name}"

  match config.get_child_module("env_var", instance_name) {
    Some(table) => {
      let m = EnvVarModule::from_table(table, module_name~)
      let variable = if m.variable.is_empty() {
        instance_name
      } else {
        m.variable
      }
      { ..m, variable, }
    }
    None => { ..EnvVarModule::default(), module_name, variable: instance_name }
  }
}

///|
pub impl @ms.PromptModule for EnvVarModule with name(self) -> String {
  self.module_name
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
