///|
pub struct Config {
  format : String
  scan_timeout : Int
  command_timeout : Int
  cache_ttl : Int
  add_newline : Bool
  modules : Map[String, ModuleConfig]
}

///|
pub struct ModuleConfig {
  disabled : Bool
  format : String
  style : String
  props : Map[String, String]
}

///|
let reserved_keys : Array[String] = ["disabled", "format", "style"]

///|
pub fn Config::default() -> Config {
  let modules : Map[String, ModuleConfig] = {}
  modules["character"] = {
    disabled: false,
    format: "$symbol ",
    style: "",
    props: {
      "success_symbol": "[❯](bold green)",
      "error_symbol": "[❯](bold red)",
      "vimcmd_symbol": "[❮](bold green)",
      "vimcmd_visual_symbol": "[❮](bold yellow)",
      "vimcmd_replace_symbol": "[❮](bold purple)",
      "vimcmd_replace_one_symbol": "[❮](bold purple)",
    },
  }
  modules["directory"] = {
    disabled: false,
    format: "[$path]($style) ",
    style: "bold cyan",
    props: { "truncation_length": "3", "truncate_to_repo": "true" },
  }
  modules["git_branch"] = {
    disabled: false,
    format: "[$symbol$branch]($style) ",
    style: "bold purple",
    props: { "truncation_length": "20", "symbol": " " },
  }
  modules["git_status"] = {
    disabled: false,
    format: "[\\[$all_status\\]]($style) ",
    style: "bold red",
    props: {
      "staged": "+",
      "modified": "!",
      "untracked": "?",
      "deleted": "✘",
    },
  }
  modules["cmd_duration"] = {
    disabled: false,
    format: "took [$duration]($style) ",
    style: "yellow bold",
    props: { "min_time": "2000" },
  }
  modules["jobs"] = {
    disabled: false,
    format: "[$symbol$number]($style) ",
    style: "bold blue",
    props: { "symbol": "✦", "number_threshold": "2" },
  }
  modules["line_break"] = { disabled: false, format: "", style: "", props: {} }
  modules["git_commit"] = {
    disabled: false,
    format: "[\\($hash\\)]($style) ",
    style: "green bold",
    props: { "only_detached": "true" },
  }
  modules["git_state"] = {
    disabled: false,
    format: "\\([$state]($style)\\) ",
    style: "bold yellow",
    props: {
      "rebase": "REBASING",
      "merge": "MERGING",
      "revert": "REVERTING",
      "cherry_pick": "CHERRY-PICKING",
      "bisect": "BISECTING",
    },
  }
  modules["hostname"] = {
    disabled: false,
    format: "[$hostname]($style) ",
    style: "bold dimmed green",
    props: { "ssh_only": "true", "trim_at": "." },
  }
  modules["username"] = {
    disabled: false,
    format: "[$user]($style) ",
    style: "",
    props: { "style_root": "bold red", "style_user": "bold yellow" },
  }
  {
    format: "$directory$git_branch$git_status\n$character",
    scan_timeout: 1000,
    command_timeout: 500,
    cache_ttl: 5000,
    add_newline: true,
    modules,
  }
}

///|
pub fn Config::get_module(self : Config, name : String) -> ModuleConfig {
  self.modules.get(name).unwrap_or(ModuleConfig::empty())
}

///|
fn ModuleConfig::empty() -> ModuleConfig {
  { disabled: false, format: "", style: "", props: {} }
}

///|
pub fn ModuleConfig::get_prop(
  self : ModuleConfig,
  key : String,
  default? : String = "",
) -> String {
  self.props.get(key).unwrap_or(default)
}

///|
pub fn ModuleConfig::get_int_prop(
  self : ModuleConfig,
  key : String,
  default? : Int = 0,
) -> Int {
  match self.props.get(key) {
    Some(v) => @strconv.parse_int(v) catch { _ => default }
    None => default
  }
}

///|
/// Parse a TOML string into a Config, merging with defaults.
pub fn Config::from_toml(toml_str : String) -> Config raise {
  let value = @toml.parse(toml_str)
  guard value is TomlTable(table) else {
    raise Failure::Failure("expected TOML table at root")
  }

  let default = Config::default()
  let format = get_string(table, "format").unwrap_or(default.format)
  let scan_timeout = get_int(table, "scan_timeout").unwrap_or(
    default.scan_timeout,
  )
  let command_timeout = get_int(table, "command_timeout").unwrap_or(
    default.command_timeout,
  )
  let cache_ttl = get_int(table, "cache_ttl").unwrap_or(default.cache_ttl)
  let add_newline = get_bool(table, "add_newline").unwrap_or(
    default.add_newline,
  )

  let modules = default.modules
  table.each(fn(name, mod_value) {
    guard mod_value is TomlTable(mod_table) else { return }
    let base = modules.get(name).unwrap_or(ModuleConfig::empty())
    modules[name] = parse_module_config(mod_table, base)
  })

  { format, scan_timeout, command_timeout, cache_ttl, add_newline, modules }
}

///|
fn parse_module_config(
  table : Map[String, @toml.TomlValue],
  base : ModuleConfig,
) -> ModuleConfig {
  let disabled = get_bool(table, "disabled").unwrap_or(base.disabled)
  let format = get_string(table, "format").unwrap_or(base.format)
  let style = get_string(table, "style").unwrap_or(base.style)

  let props = base.props
  table.each(fn(key, value) {
    if reserved_keys.contains(key) {
      return
    }
    match toml_value_to_string(value) {
      Some(s) => props[key] = s
      None => ()
    }
  })

  { disabled, format, style, props }
}

///|
fn toml_value_to_string(value : @toml.TomlValue) -> String? {
  match value {
    TomlString(s) => Some(s)
    TomlInteger(n) => Some(n.to_string())
    TomlBoolean(b) => Some(b.to_string())
    TomlFloat(f) => Some(f.to_string())
    _ => None
  }
}

///|
/// Convert a Config back to a TOML string.
pub fn Config::to_toml(self : Config) -> String {
  let header = [
    "format = \{quote(self.format)}",
    "scan_timeout = \{self.scan_timeout}",
    "command_timeout = \{self.command_timeout}",
    "cache_ttl = \{self.cache_ttl}",
    "add_newline = \{self.add_newline}",
  ].join("\n")

  let module_names = self.modules.keys().collect()
  module_names.sort()

  let sections = module_names
    .iter()
    .filter_map(fn(name) {
      self.modules.get(name).map(fn(mc) { module_to_toml(name, mc) })
    })
    .collect()
    .join("")

  header + "\n" + sections
}

///|
fn module_to_toml(name : String, mc : ModuleConfig) -> String {
  let lines : Array[String] = ["\n[\{name}]"]

  if mc.disabled {
    lines.push("disabled = true")
  }
  if not(mc.format.is_empty()) {
    lines.push("format = \{quote(mc.format)}")
  }
  if not(mc.style.is_empty()) {
    lines.push("style = \{quote(mc.style)}")
  }

  let prop_keys = mc.props.keys().collect()
  prop_keys.sort()
  prop_keys.each(fn(key) {
    match mc.props.get(key) {
      Some(value) => lines.push("\{key} = \{quote(value)}")
      None => ()
    }
  })

  lines.join("\n") + "\n"
}

///|
fn quote(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('"')
  for ch in s {
    match ch {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(ch)
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
fn get_string(table : Map[String, @toml.TomlValue], key : String) -> String? {
  match table.get(key) {
    Some(TomlString(s)) => Some(s)
    _ => None
  }
}

///|
fn get_int(table : Map[String, @toml.TomlValue], key : String) -> Int? {
  match table.get(key) {
    Some(TomlInteger(n)) => Some(n.to_int())
    _ => None
  }
}

///|
fn get_bool(table : Map[String, @toml.TomlValue], key : String) -> Bool? {
  match table.get(key) {
    Some(TomlBoolean(b)) => Some(b)
    _ => None
  }
}
