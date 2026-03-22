///|
pub struct DirenvModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  allowed_msg : String
  not_allowed_msg : String
  denied_msg : String
  loaded_msg : String
  unloaded_msg : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DirenvModule::default() -> DirenvModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$loaded/$allowed]($style) ",
    style: "bold bright-yellow",
    symbol: "direnv ",
    allowed_msg: "allowed",
    not_allowed_msg: "not allowed",
    denied_msg: "denied",
    loaded_msg: "loaded",
    unloaded_msg: "not loaded",
    detect_files: [".envrc"],
    detect_extensions: [],
  }
}

///|
pub fn DirenvModule::from_table(table : @config.ModuleTable) -> DirenvModule {
  let d = DirenvModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    allowed_msg: table.get_string("allowed_msg").unwrap_or(d.allowed_msg),
    not_allowed_msg: table
    .get_string("not_allowed_msg")
    .unwrap_or(d.not_allowed_msg),
    denied_msg: table.get_string("denied_msg").unwrap_or(d.denied_msg),
    loaded_msg: table.get_string("loaded_msg").unwrap_or(d.loaded_msg),
    unloaded_msg: table.get_string("unloaded_msg").unwrap_or(d.unloaded_msg),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn DirenvModule::from_config(config : @config.Config) -> DirenvModule {
  match config.get_raw_module("direnv") {
    Some(table) => DirenvModule::from_table(table)
    None => DirenvModule::default()
  }
}

///|
pub impl @ms.PromptModule for DirenvModule with name(_self) -> String {
  "direnv"
}

///|
pub impl @ms.PromptModule for DirenvModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DirenvModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let has_env = not(@sys.get_env_var("DIRENV_FILE").unwrap_or("").is_empty())
  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no direnv detected")
  }

  let output = @exec.exec_cmd_full("direnv", ["status"])
  let (loaded, allowed) = parse_direnv_status(output)

  let loaded_str = if loaded { self.loaded_msg } else { self.unloaded_msg }
  let allowed_str = match allowed {
    "allowed" => self.allowed_msg
    "denied" => self.denied_msg
    _ => self.not_allowed_msg
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "loaded": loaded_str,
    "allowed": allowed_str,
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
fn parse_direnv_status(output : String) -> (Bool, String) {
  let lines = output.split("\n").collect()
  let mut loaded = false
  let mut allowed = "not_allowed"

  for line in lines {
    let s = line.to_string()

    if s.contains("No .envrc") || s.contains("No .env") {
      loaded = false
    } else if s.contains("Found RC") || s.contains("Loaded RC") {
      loaded = true

      if s.contains("allowed 0") || s.contains("allowed true") {
        allowed = "allowed"
      } else if s.contains("allowed 2") || s.contains("allowed false") {
        allowed = "denied"
      } else if s.contains("allowed 1") {
        allowed = "not_allowed"
      }
    }
  }

  (loaded, allowed)
}

///|
pub fn DirenvModule::schema() -> @config.ModuleSchema {
  let d = DirenvModule::default()
  {
    name: "direnv",
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
        name: "allowed_msg",
        field_type: @config.FString,
        default_value: d.allowed_msg,
      },
      {
        name: "not_allowed_msg",
        field_type: @config.FString,
        default_value: d.not_allowed_msg,
      },
      {
        name: "denied_msg",
        field_type: @config.FString,
        default_value: d.denied_msg,
      },
      {
        name: "loaded_msg",
        field_type: @config.FString,
        default_value: d.loaded_msg,
      },
      {
        name: "unloaded_msg",
        field_type: @config.FString,
        default_value: d.unloaded_msg,
      },
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
    ],
  }
}
