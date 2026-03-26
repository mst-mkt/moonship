///|
pub struct DockerContextModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  only_with_files : Bool
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn DockerContextModule::default() -> DockerContextModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$context]($style) ",
    style: "blue bold",
    symbol: "🐳 ",
    only_with_files: true,
    detect_files: [
      "compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml",
      "Dockerfile",
    ],
    detect_extensions: [],
    detect_folders: [],
  }
}

///|
pub fn DockerContextModule::from_table(
  table : @config.ModuleTable,
) -> DockerContextModule {
  let d = DockerContextModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    only_with_files: table
    .get_bool("only_with_files")
    .unwrap_or(d.only_with_files),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn DockerContextModule::from_config(
  config : @config.Config,
) -> DockerContextModule {
  match config.get_raw_module("docker_context") {
    Some(table) => DockerContextModule::from_table(table)
    None => DockerContextModule::default()
  }
}

///|
pub impl @ms.PromptModule for DockerContextModule with name(_self) -> String {
  "docker_context"
}

///|
pub impl @ms.PromptModule for DockerContextModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DockerContextModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  if self.only_with_files {
    guard @exec.detect_project(
      ctx.cwd,
      self.detect_files,
      self.detect_extensions,
      folders=self.detect_folders,
    ) else {
      return Skipped("no Docker files detected")
    }
  }

  let context = get_docker_context(ctx)
  guard not(context.is_empty()) else { return Skipped("no docker context") }

  guard not(is_default_context(context)) else {
    return Skipped("default docker context")
  }

  let vars : Map[String, String] = {
    "context": context,
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
fn get_docker_context(ctx : @context.Context) -> String {
  let machine = @sys.get_env_var("DOCKER_MACHINE_NAME").unwrap_or("")
  if not(machine.is_empty()) {
    return machine
  }

  let host = @sys.get_env_var("DOCKER_HOST").unwrap_or("")
  if not(host.is_empty()) {
    return host
  }

  let env_context = @sys.get_env_var("DOCKER_CONTEXT").unwrap_or("")
  if not(env_context.is_empty()) {
    return env_context
  }

  let config_dir = @sys.get_env_var("DOCKER_CONFIG").unwrap_or("")
  let home = ctx.home_dir
  let config_path = if not(config_dir.is_empty()) {
    config_dir + "/config.json"
  } else if not(home.is_empty()) {
    home + "/.docker/config.json"
  } else {
    return ""
  }

  let content = @fs.read_file_to_string(config_path) catch { _ => return "" }
  parse_docker_config_context(content)
}

///|
fn parse_docker_config_context(content : String) -> String {
  let key = "\"currentContext\""
  match content.find(key) {
    None => ""
    Some(idx) => {
      let after = content[idx + key.length():].to_string()

      let colon_pos = match after.find(":") {
        Some(p) => p
        None => return ""
      }

      let after_colon = after[colon_pos + 1:].to_string()

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
  }
}

///|
fn is_default_context(context : String) -> Bool {
  context == "default" ||
  context == "desktop-linux" ||
  context.has_prefix("unix://")
}

///|
pub fn DockerContextModule::schema() -> @config.ModuleSchema {
  let d = DockerContextModule::default()
  {
    name: "docker_context",
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
        name: "only_with_files",
        field_type: @config.FBool,
        default_value: d.only_with_files.to_string(),
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
