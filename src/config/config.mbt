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
    format: "[$path]($style)[$read_only]($read_only_style) ",
    style: "cyan bold",
    props: { "truncation_length": "3", "truncate_to_repo": "true" },
  }
  modules["git_branch"] = {
    disabled: false,
    format: "on [$symbol$branch(:$remote_branch)]($style) ",
    style: "bold purple",
    props: { "truncation_length": "9999", "symbol": " " },
  }
  modules["git_status"] = {
    disabled: false,
    format: "([\\[$all_status$ahead_behind\\]]($style) )",
    style: "red bold",
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
    format: "[\\($hash$tag\\)]($style) ",
    style: "green bold",
    props: { "only_detached": "true" },
  }
  modules["git_state"] = {
    disabled: false,
    format: "\\([$state( $progress_current/$progress_total)]($style)\\) ",
    style: "bold yellow",
    props: {
      "rebase": "REBASING",
      "merge": "MERGING",
      "revert": "REVERTING",
      "cherry_pick": "CHERRY-PICKING",
      "bisect": "BISECTING",
    },
  }
  modules["git_metrics"] = {
    disabled: true,
    format: "([+$added]($added_style) )([-$deleted]($deleted_style) )",
    style: "",
    props: {
      "added_style": "bold green",
      "deleted_style": "bold red",
      "only_nonzero_diffs": "true",
    },
  }
  modules["package"] = {
    disabled: false,
    format: "is [$symbol$version]($style) ",
    style: "208 bold",
    props: { "symbol": "📦 " },
  }
  modules["bun"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    props: { "symbol": "🥟 " },
  }
  modules["nodejs"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    props: { "symbol": " " },
  }
  modules["python"] = {
    disabled: false,
    format: "via [$symbol$pyenv_prefix($version )(\\($virtualenv\\) )]($style)",
    style: "yellow bold",
    props: {
      "symbol": "🐍 ",
      "pyenv_version_name": "false",
      "pyenv_prefix": "pyenv ",
    },
  }
  modules["rust"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    props: { "symbol": "🦀 " },
  }
  modules["golang"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold cyan",
    props: { "symbol": "🐹 " },
  }
  modules["java"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "red dimmed",
    props: { "symbol": "☕ " },
  }
  modules["ruby"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    props: { "symbol": "💎 " },
  }
  modules["deno"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "green bold",
    props: { "symbol": "🦕 " },
  }
  modules["dart"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "🎯 " },
  }
  modules["elixir"] = {
    disabled: false,
    format: "via [$symbol($version \\(OTP $otp_version\\) )]($style)",
    style: "bold purple",
    props: { "symbol": "💧 " },
  }
  modules["lua"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "🌙 ", "lua_binary": "lua" },
  }
  modules["php"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "147 bold",
    props: { "symbol": "🐘 " },
  }
  modules["perl"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "149 bold",
    props: { "symbol": "🐪 " },
  }
  modules["kotlin"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "🅺 ", "kotlin_binary": "kotlin" },
  }
  modules["swift"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 202",
    props: { "symbol": "🐦 " },
  }
  modules["scala"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "red bold",
    props: { "symbol": "🆂 " },
  }
  modules["zig"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold yellow",
    props: { "symbol": "↯ " },
  }
  modules["dotnet"] = {
    disabled: false,
    format: "via [$symbol($version )(🎯 $tfm )]($style)",
    style: "blue bold",
    props: { "symbol": ".NET " },
  }
  modules["moonbit"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 125",
    props: { "symbol": "🐰 " },
  }
  modules["julia"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold purple",
    props: { "symbol": "ஃ " },
  }
  modules["nim"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "yellow bold",
    props: { "symbol": "👑 " },
  }
  modules["gleam"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #FFAFF3",
    props: { "symbol": "⭐ " },
  }
  modules["erlang"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    props: { "symbol": " " },
  }
  modules["elm"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    props: { "symbol": "🌳 " },
  }
  modules["haskell"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold purple",
    props: { "symbol": "λ " },
  }
  modules["crystal"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    props: { "symbol": "🔮 " },
  }
  modules["c"] = {
    disabled: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "149 bold",
    props: { "symbol": "C " },
  }
  modules["cpp"] = {
    disabled: true,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "149 bold",
    props: { "symbol": "C++ " },
  }
  modules["cmake"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "△ " },
  }
  modules["terraform"] = {
    disabled: false,
    format: "via [$symbol$workspace]($style) ",
    style: "bold 105",
    props: { "symbol": "💠 " },
  }
  modules["gradle"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-cyan",
    props: { "symbol": "🅶 " },
  }
  modules["maven"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-cyan",
    props: { "symbol": "🅼 " },
  }
  modules["ocaml"] = {
    disabled: false,
    format: "via [$symbol($version )(\\($switch_indicator$switch_name\\) )]($style)",
    style: "bold yellow",
    props: {
      "symbol": "🐫 ",
      "global_switch_indicator": "",
      "local_switch_indicator": "*",
    },
  }
  modules["haxe"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold fg:202",
    props: { "symbol": "⌘ " },
  }
  modules["fortran"] = {
    disabled: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "bold purple",
    props: { "symbol": "🅵  " },
  }
  modules["purescript"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    props: { "symbol": "<=> " },
  }
  modules["buf"] = {
    disabled: false,
    format: "with [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "🐃 " },
  }
  modules["cobol"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "⚙️ " },
  }
  modules["fennel"] = {
    disabled: true,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    props: { "symbol": "🧅 " },
  }
  modules["helm"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    props: { "symbol": "⎈ " },
  }
  modules["mojo"] = {
    disabled: false,
    format: "with [$symbol($version )]($style)",
    style: "bold 208",
    props: { "symbol": "🔥 " },
  }
  modules["odin"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-blue",
    props: { "symbol": "Ø " },
  }
  modules["opa"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    props: { "symbol": "🪖 " },
  }
  modules["quarto"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #75AADB",
    props: { "symbol": "⨁ " },
  }
  modules["red"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "red bold",
    props: { "symbol": "🔺 " },
  }
  modules["daml"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold cyan",
    props: { "symbol": "Λ " },
  }
  modules["raku"] = {
    disabled: false,
    format: "via [$symbol($version-$vm_version )]($style)",
    style: "149 bold",
    props: { "symbol": "🦋 " },
  }
  modules["rlang"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    props: { "symbol": "📐 " },
  }
  modules["solidity"] = {
    disabled: false,
    format: "via [$symbol($version)]($style)",
    style: "bold blue",
    props: { "symbol": "S " },
  }
  modules["typst"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #0093A7",
    props: { "symbol": "t " },
  }
  modules["vlang"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    props: { "symbol": "V " },
  }
  modules["vagrant"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    props: { "symbol": "⍱ " },
  }
  modules["xmake"] = {
    disabled: false,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    props: { "symbol": "△ " },
  }
  modules["shlvl"] = {
    disabled: true,
    format: "[$symbol$shlvl]($style) ",
    style: "bold yellow",
    props: {
      "symbol": "↕️  ",
      "threshold": "2",
      "repeat": "false",
      "repeat_offset": "0",
    },
  }
  modules["os"] = {
    disabled: true,
    format: "[$symbol]($style)",
    style: "bold white",
    props: {},
  }
  modules["shell"] = {
    disabled: true,
    format: "[$indicator]($style) ",
    style: "white bold",
    props: {
      "bash_indicator": "bsh",
      "fish_indicator": "fsh",
      "zsh_indicator": "zsh",
      "unknown_indicator": "",
    },
  }
  modules["container"] = {
    disabled: false,
    format: "[$symbol \\[$name\\]]($style) ",
    style: "red bold dimmed",
    props: { "symbol": "⬢" },
  }
  modules["sudo"] = {
    disabled: true,
    format: "[as $symbol]($style)",
    style: "bold blue",
    props: { "symbol": "🧙 " },
  }
  modules["status"] = {
    disabled: true,
    format: "[$symbol$status]($style) ",
    style: "bold red",
    props: {
      "symbol": "❌",
      "success_symbol": "",
      "not_executable_symbol": "🚫",
      "not_found_symbol": "🔍",
      "map_symbol": "false",
    },
  }
  modules["nix_shell"] = {
    disabled: false,
    format: "via [$symbol$state( \\($name\\))]($style) ",
    style: "bold blue",
    props: {
      "symbol": "❄️  ",
      "impure_msg": "impure",
      "pure_msg": "pure",
      "unknown_msg": "",
      "heuristic": "false",
    },
  }
  modules["conda"] = {
    disabled: false,
    format: "via [$symbol$environment]($style) ",
    style: "green bold",
    props: { "symbol": "🅒 ", "ignore_base": "true" },
  }
  modules["pixi"] = {
    disabled: false,
    format: "via [$symbol($version )(\\($environment\\) )]($style)",
    style: "yellow bold",
    props: { "symbol": "🧚 ", "show_default_environment": "true" },
  }
  modules["meson"] = {
    disabled: false,
    format: "via [$symbol$project]($style) ",
    style: "blue bold",
    props: { "symbol": "⬢ " },
  }
  modules["guix_shell"] = {
    disabled: false,
    format: "via [$symbol]($style) ",
    style: "yellow bold",
    props: { "symbol": "🐃 " },
  }
  modules["spack"] = {
    disabled: false,
    format: "via [$symbol$environment]($style) ",
    style: "blue bold",
    props: { "symbol": "🅢 " },
  }
  modules["memory_usage"] = {
    disabled: true,
    format: "via $symbol[$ram( | $swap)]($style) ",
    style: "white bold dimmed",
    props: { "symbol": "🐏 ", "threshold": "75" },
  }
  modules["direnv"] = {
    disabled: true,
    format: "[$symbol$loaded/$allowed]($style) ",
    style: "bold bright-yellow",
    props: {
      "symbol": "direnv ",
      "allowed_msg": "allowed",
      "not_allowed_msg": "not allowed",
      "denied_msg": "denied",
      "loaded_msg": "loaded",
      "unloaded_msg": "not loaded",
    },
  }
  modules["mise"] = {
    disabled: true,
    format: "on [$symbol$health]($style) ",
    style: "bold purple",
    props: {
      "symbol": "mise ",
      "healthy_symbol": "healthy",
      "unhealthy_symbol": "unhealthy",
    },
  }
  modules["aws"] = {
    disabled: false,
    format: "on [$symbol($profile )(\\($region\\) )]($style)",
    style: "bold yellow",
    props: { "symbol": "☁️  " },
  }
  modules["gcloud"] = {
    disabled: false,
    format: "on [$symbol$account(@$domain)(\\($region\\))]($style) ",
    style: "bold blue",
    props: { "symbol": "☁️  " },
  }
  modules["azure"] = {
    disabled: true,
    format: "on [$symbol($subscription)]($style) ",
    style: "blue bold",
    props: { "symbol": "󰠅 " },
  }
  modules["openstack"] = {
    disabled: false,
    format: "on [$symbol$cloud(\\($project\\))]($style) ",
    style: "bold yellow",
    props: { "symbol": "☁️  " },
  }
  modules["singularity"] = {
    disabled: false,
    format: "[$symbol\\[$env\\]]($style) ",
    style: "blue bold dimmed",
    props: { "symbol": "" },
  }
  modules["kubernetes"] = {
    disabled: true,
    format: "[$symbol$context( \\($namespace\\))]($style) in ",
    style: "cyan bold",
    props: { "symbol": "☸ " },
  }
  modules["nats"] = {
    disabled: true,
    format: "[$symbol($name )]($style)",
    style: "bold purple",
    props: { "symbol": "✉️ " },
  }
  modules["pulumi"] = {
    disabled: false,
    format: "via [$symbol($username@)$stack]($style) ",
    style: "bold 5",
    props: { "symbol": " " },
  }
  modules["docker_context"] = {
    disabled: false,
    format: "via [$symbol$context]($style) ",
    style: "blue bold",
    props: { "symbol": "🐳 ", "only_with_files": "true" },
  }
  modules["time"] = {
    disabled: true,
    format: "at [$time]($style) ",
    style: "bold yellow",
    props: {
      "use_12hr": "false",
      "time_format": "",
      "utc_time_offset": "local",
    },
  }
  modules["fossil_branch"] = {
    disabled: true,
    format: "on [$symbol$branch]($style) ",
    style: "bold purple",
    props: { "symbol": " " },
  }
  modules["fossil_metrics"] = {
    disabled: true,
    format: "([+$added]($added_style) )([-$deleted]($deleted_style) )",
    style: "",
    props: {
      "added_style": "bold green",
      "deleted_style": "bold red",
      "only_nonzero_diffs": "true",
    },
  }
  modules["vcsh"] = {
    disabled: false,
    format: "vcsh [$symbol$repo]($style) ",
    style: "bold yellow",
    props: { "symbol": "" },
  }
  modules["pijul_channel"] = {
    disabled: true,
    format: "on [$symbol$channel]($style) ",
    style: "bold purple",
    props: { "symbol": " " },
  }
  modules["hg_branch"] = {
    disabled: true,
    format: "on [$symbol$branch(:$topic)]($style) ",
    style: "bold purple",
    props: { "symbol": " " },
  }
  modules["hg_state"] = {
    disabled: true,
    format: "(\\($state\\) )",
    style: "bold yellow",
    props: {},
  }
  modules["env_var"] = {
    disabled: false,
    format: "with [$symbol$env_value]($style) ",
    style: "black bold dimmed",
    props: { "symbol": "", "variable": "", "default": "" },
  }
  modules["hostname"] = {
    disabled: false,
    format: "[$ssh_symbol$hostname]($style) in ",
    style: "green dimmed bold",
    props: { "ssh_only": "true", "trim_at": "." },
  }
  modules["username"] = {
    disabled: false,
    format: "[$user]($style) in ",
    style: "",
    props: { "style_root": "red bold", "style_user": "yellow bold" },
  }
  {
    format: "$all",
    scan_timeout: 30,
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
