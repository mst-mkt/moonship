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

    let lines = content.split("\n").map(fn(s) { s.to_string() }).collect()
    let value = if lines.length() > 0 { lines[0] } else { "" }

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
  content
  .split("\n")
  .map(fn(s) { s.to_string() })
  .find_first(fn(s) {
    s.has_prefix("name=\"") ||
    s.has_prefix("name=") ||
    s.has_prefix("image=\"") ||
    s.has_prefix("image=")
  })
  .map(fn(s) {
    if s.has_prefix("name=\"") || s.has_prefix("name=") {
      let start = if s.has_prefix("name=\"") { 6 } else { 5 }
      let rest = s[start:].to_string()
      match rest.find("\"") {
        Some(idx) => rest[:idx].to_string()
        None => rest
      }
    } else {
      let start = if s.has_prefix("image=\"") { 7 } else { 6 }
      let rest = s[start:].to_string()
      let image = match rest.find("\"") {
        Some(idx) => rest[:idx].to_string()
        None => rest
      }
      strip_registry_path(image)
    }
  })
  .unwrap_or("")
}

///|
fn strip_registry_path(image : String) -> String {
  let init : (Int?, Int) = (None, 0)

  match
    image
    .iter()
    .fold(init~, fn(acc, ch) {
      let (result, i) = acc
      (if ch == '/' { Some(i) } else { result }, i + 1)
    }).0 {
    Some(last) => image[last + 1:].to_string()
    None => image
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
