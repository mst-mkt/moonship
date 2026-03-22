///|
pub struct ContainerModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn ContainerModule::default() -> ContainerModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol \\[$name\\]]($style) ",
    style: "red bold dimmed",
    symbol: "⬢",
  }
}

///|
pub fn ContainerModule::from_table(
  table : @config.ModuleTable,
) -> ContainerModule {
  let d = ContainerModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn ContainerModule::from_config(config : @config.Config) -> ContainerModule {
  match config.get_raw_module("container") {
    Some(table) => ContainerModule::from_table(table)
    None => ContainerModule::default()
  }
}

///|
pub impl @ms.PromptModule for ContainerModule with name(_self) -> String {
  "container"
}

///|
pub impl @ms.PromptModule for ContainerModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for ContainerModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let name = detect_container()
  guard not(name.is_empty()) else { return Skipped("not in a container") }

  let vars : Map[String, String] = {
    "name": name,
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
fn detect_container() -> String {
  if @fs.path_exists("/proc/vz") && not(@fs.path_exists("/proc/bc")) {
    return "OpenVZ"
  }

  if @fs.path_exists("/run/host/container-manager") {
    return "OCI"
  }

  if @fs.path_exists("/dev/incus/sock") {
    return "Incus"
  }

  if @fs.path_exists("/run/.containerenv") {
    let content = @fs.read_file_to_string("/run/.containerenv") catch {
      _ => return "podman"
    }

    let name = parse_containerenv_name(content)
    return if name.is_empty() { "podman" } else { name }
  }

  if @fs.path_exists("/run/systemd/container") {
    let content = @fs.read_file_to_string("/run/systemd/container") catch {
      _ => return ""
    }

    let lines = content.split("\n").collect()
    let value = if lines.length() > 0 { lines[0].to_string() } else { "" }

    if value == "wsl" {
      return ""
    } else if value == "docker" {
      return "Docker"
    } else {
      return "Systemd"
    }
  }

  if @fs.path_exists("/.dockerenv") {
    return "Docker"
  }

  ""
}

///|
fn parse_containerenv_name(content : String) -> String {
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("name=\"") || s.has_prefix("name=") {
      let start = if s.has_prefix("name=\"") { 6 } else { 5 }
      let rest = s[start:].to_string()

      match rest.find("\"") {
        Some(idx) => return rest[:idx].to_string()
        None => return rest
      }
    }

    if s.has_prefix("image=\"") || s.has_prefix("image=") {
      let start = if s.has_prefix("image=\"") { 7 } else { 6 }
      let rest = s[start:].to_string()

      let image = match rest.find("\"") {
        Some(idx) => rest[:idx].to_string()
        None => rest
      }

      return strip_registry_path(image)
    }
  }

  ""
}

///|
fn strip_registry_path(image : String) -> String {
  let mut last_slash = -1

  for i = 0; i < image.length(); i = i + 1 {
    if image[i].unsafe_to_char() == '/' {
      last_slash = i
    }
  }

  if last_slash >= 0 {
    image[last_slash + 1:].to_string()
  } else {
    image
  }
}

///|
pub fn ContainerModule::schema() -> @config.ModuleSchema {
  let d = ContainerModule::default()
  {
    name: "container",
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
