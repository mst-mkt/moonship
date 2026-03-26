///|
pub struct AwsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  region_aliases : Map[String, String]
  profile_aliases : Map[String, String]
  expiration_symbol : String
  force_display : Bool
}

///|
pub fn AwsModule::default() -> AwsModule {
  {
    disabled: false,
    async_render: false,
    format: "on [$symbol($profile )(\\($region\\) )]($style)",
    style: "bold yellow",
    symbol: "☁️  ",
    region_aliases: {},
    profile_aliases: {},
    expiration_symbol: "X",
    force_display: false,
  }
}

///|
pub fn AwsModule::from_table(table : @config.ModuleTable) -> AwsModule {
  let d = AwsModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    region_aliases: table.get_string_map("region_aliases"),
    profile_aliases: table.get_string_map("profile_aliases"),
    expiration_symbol: table
    .get_string("expiration_symbol")
    .unwrap_or(d.expiration_symbol),
    force_display: table
    .get_bool("force_display")
    .unwrap_or(d.force_display),
  }
}

///|
pub fn AwsModule::from_config(config : @config.Config) -> AwsModule {
  match config.get_raw_module("aws") {
    Some(table) => AwsModule::from_table(table)
    None => AwsModule::default()
  }
}

///|
pub impl @ms.PromptModule for AwsModule with name(_self) -> String {
  "aws"
}

///|
pub impl @ms.PromptModule for AwsModule with is_async(self) -> Bool {
  self.async_render
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
    vars["profile"] = self.profile_aliases.get(profile).unwrap_or(profile)
  }

  if not(region.is_empty()) {
    vars["region"] = self.region_aliases.get(region).unwrap_or(region)
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
  [
    "AWSU_PROFILE", "AWS_VAULT", "AWSUME_PROFILE", "AWS_PROFILE", "AWS_SSO_PROFILE",
  ]
  .iter()
  .map(fn(v) { @sys.get_env_var(v).unwrap_or("") })
  .find_first(fn(val) { not(val.is_empty()) })
  .unwrap_or("")
}

///|
fn get_aws_region() -> String {
  let val = @sys.get_env_var("AWS_REGION").unwrap_or("")
  if not(val.is_empty()) {
    return val
  }

  @sys.get_env_var("AWS_DEFAULT_REGION").unwrap_or("")
}

///|
pub fn AwsModule::schema() -> @config.ModuleSchema {
  let d = AwsModule::default()
  {
    name: "aws",
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
