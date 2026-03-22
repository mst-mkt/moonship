///|
pub struct AwsModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn AwsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("aws"),
) -> AwsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="☁️  "),
  }
}

///|
pub fn AwsModule::from_config(config : @config.Config) -> AwsModule {
  AwsModule::new(config=config.get_module("aws"))
}

///|
pub impl @ms.PromptModule for AwsModule with name(_self) -> String {
  "aws"
}

///|
pub impl @ms.PromptModule for AwsModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for AwsModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let profile = get_aws_profile()
  let region = get_aws_region()
  guard not(profile.is_empty()) || not(region.is_empty()) else {
    return Skipped("no AWS profile or region")
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(profile.is_empty()) {
    vars["profile"] = profile
  }

  if not(region.is_empty()) {
    vars["region"] = region
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn get_aws_profile() -> String {
  let env_vars = [
    "AWSU_PROFILE", "AWS_VAULT", "AWSUME_PROFILE", "AWS_PROFILE", "AWS_SSO_PROFILE",
  ]

  for v in env_vars {
    let val = @sys.get_env_var(v).unwrap_or("")
    if not(val.is_empty()) {
      return val
    }
  }

  ""
}

///|
fn get_aws_region() -> String {
  let val = @sys.get_env_var("AWS_REGION").unwrap_or("")
  if not(val.is_empty()) {
    return val
  }

  @sys.get_env_var("AWS_DEFAULT_REGION").unwrap_or("")
}
