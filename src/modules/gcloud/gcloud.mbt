///|
pub struct GcloudModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn GcloudModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "gcloud",
  ),
) -> GcloudModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="☁️  "),
  }
}

///|
pub fn GcloudModule::from_config(config : @config.Config) -> GcloudModule {
  GcloudModule::new(config=config.get_module("gcloud"))
}

///|
pub impl @ms.PromptModule for GcloudModule with name(_self) -> String {
  "gcloud"
}

///|
pub impl @ms.PromptModule for GcloudModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let project = @sys.get_env_var("CLOUDSDK_CORE_PROJECT").unwrap_or("")
  let account = @sys.get_env_var("CLOUDSDK_CORE_ACCOUNT").unwrap_or("")
  guard not(project.is_empty()) || not(account.is_empty()) else {
    return Skipped("no gcloud config detected")
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(account.is_empty()) {
    match account.find("@") {
      Some(idx) => {
        vars["account"] = account[:idx].to_string()
        vars["domain"] = account[idx + 1:].to_string()
      }
      None => vars["account"] = account
    }
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
