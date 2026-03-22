///|
pub struct AzureModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn AzureModule::default() -> AzureModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol($subscription)]($style) ",
    style: "blue bold",
    symbol: "󰠅 ",
  }
}

///|
pub fn AzureModule::from_table(table : @config.ModuleTable) -> AzureModule {
  let d = AzureModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn AzureModule::from_config(config : @config.Config) -> AzureModule {
  match config.get_raw_module("azure") {
    Some(table) => AzureModule::from_table(table)
    None => AzureModule::default()
  }
}

///|
pub impl @ms.PromptModule for AzureModule with name(_self) -> String {
  "azure"
}

///|
pub impl @ms.PromptModule for AzureModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for AzureModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let config_dir = @sys.get_env_var("AZURE_CONFIG_DIR").unwrap_or("")
  let home = ctx.home_dir
  let profile_path = if not(config_dir.is_empty()) {
    config_dir + "/azureProfile.json"
  } else if not(home.is_empty()) {
    home + "/.azure/azureProfile.json"
  } else {
    return Skipped("no azure config path")
  }

  let content = @fs.read_file_to_string(profile_path) catch {
    _ => return Skipped("could not read azure profile")
  }

  let subscription = parse_azure_subscription(content)
  guard not(subscription.is_empty()) else {
    return Skipped("no default azure subscription")
  }

  let vars : Map[String, String] = {
    "subscription": subscription,
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
fn parse_azure_subscription(content : String) -> String {
  let default_marker = "\"isDefault\""
  let name_key = "\"name\""

  loop 0 {
    pos => {
      guard pos < content.length() else { break "" }

      let remaining = content[pos:].to_string()
      match remaining.find(default_marker) {
        None => break ""
        Some(idx) => {
          let after = content[pos + idx + default_marker.length():].to_string()
          if is_json_true(after) {
            let before = content[:pos + idx].to_string()
            match find_last_name_value(before, name_key) {
              "" => {
                let after_default = content[pos + idx:].to_string()
                break find_first_name_value(after_default, name_key)
              }
              name => break name
            }
          }
          continue pos + idx + default_marker.length()
        }
      }
    }
  }
}

///|
fn find_last_name_value(s : String, key : String) -> String {
  loop ("", 0) {
    (result, pos) => {
      guard pos < s.length() else { break result }

      let remaining = s[pos:].to_string()
      match remaining.find(key) {
        None => break result
        Some(idx) => {
          let after_key = s[pos + idx + key.length():].to_string()
          let val = extract_json_string_value(after_key)
          let new_result = if not(val.is_empty()) { val } else { result }
          continue (new_result, pos + idx + key.length())
        }
      }
    }
  }
}

///|
fn find_first_name_value(s : String, key : String) -> String {
  match s.find(key) {
    None => ""
    Some(idx) => {
      let after = s[idx + key.length():].to_string()
      extract_json_string_value(after)
    }
  }
}

///|
fn extract_json_string_value(s : String) -> String {
  let colon = match s.find(":") {
    Some(p) => p
    None => return ""
  }

  let after_colon = s[colon + 1:].to_string()
  let quote_start = match after_colon.find("\"") {
    Some(p) => p
    None => return ""
  }

  let after_quote = after_colon[quote_start + 1:].to_string()
  let quote_end = match after_quote.find("\"") {
    Some(p) => p
    None => return ""
  }

  after_quote[:quote_end].to_string()
}

///|
fn is_json_true(s : String) -> Bool {
  let colon = match s.find(":") {
    Some(p) => p
    None => return false
  }

  s[colon + 1:]
  .to_string()
  .trim_start(chars=" \t\n\r")
  .to_string()
  .has_prefix("true")
}

///|
pub fn AzureModule::schema() -> @config.ModuleSchema {
  let d = AzureModule::default()
  {
    name: "azure",
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
