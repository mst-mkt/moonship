///|
pub struct DockerContextModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  only_with_files : Bool
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DockerContextModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "docker_context",
  ),
) -> DockerContextModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐳 "),
    only_with_files: config.get_prop("only_with_files", default="true") !=
    "false",
    detect_files: [
      "compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml",
      "Dockerfile",
    ],
    detect_extensions: [],
  }
}

///|
pub fn DockerContextModule::from_config(
  config : @config.Config,
) -> DockerContextModule {
  DockerContextModule::new(config=config.get_module("docker_context"))
}

///|
pub impl @ms.PromptModule for DockerContextModule with name(_self) -> String {
  "docker_context"
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
