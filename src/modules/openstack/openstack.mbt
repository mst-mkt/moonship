///|
pub struct OpenstackModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn OpenstackModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "openstack",
  ),
) -> OpenstackModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="☁️  "),
  }
}

///|
pub fn OpenstackModule::from_config(config : @config.Config) -> OpenstackModule {
  OpenstackModule::new(config=config.get_module("openstack"))
}

///|
pub impl @ms.PromptModule for OpenstackModule with name(_self) -> String {
  "openstack"
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
