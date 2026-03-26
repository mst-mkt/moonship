///|
pub struct OpenstackModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn OpenstackModule::default() -> OpenstackModule {
  {
    disabled: false,
    async_render: false,
    format: "on [$symbol$cloud(\\($project\\))]($style) ",
    style: "bold yellow",
    symbol: "☁️  ",
  }
}

///|
pub fn OpenstackModule::from_table(
  table : @config.ModuleTable,
) -> OpenstackModule {
  let d = OpenstackModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn OpenstackModule::from_config(config : @config.Config) -> OpenstackModule {
  match config.get_raw_module("openstack") {
    Some(table) => OpenstackModule::from_table(table)
    None => OpenstackModule::default()
  }
}

///|
pub impl @ms.PromptModule for OpenstackModule with name(_self) -> String {
  "openstack"
}

///|
pub impl @ms.PromptModule for OpenstackModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for OpenstackModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let cloud = @sys.get_env_var("OS_CLOUD").unwrap_or("")
  guard not(cloud.is_empty()) else { return Skipped("no openstack cloud set") }

  let project = @sys.get_env_var("OS_PROJECT_NAME").unwrap_or("")
  let vars : Map[String, String] = {
    "cloud": cloud,
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(project.is_empty()) {
    vars["project"] = project
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
pub fn OpenstackModule::schema() -> @config.ModuleSchema {
  let d = OpenstackModule::default()
  {
    name: "openstack",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
