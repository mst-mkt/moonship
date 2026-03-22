///|
pub struct OsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
}

///|
pub fn OsModule::default() -> OsModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol]($style)",
    style: "bold white",
  }
}

///|
pub fn OsModule::from_toml_table(table : @config.ModuleTable) -> OsModule {
  let d = OsModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
  }
}

///|
pub fn OsModule::from_config(config : @config.Config) -> OsModule {
  match config.get_raw_module("os") {
    Some(table) => OsModule::from_toml_table(table)
    None => OsModule::default()
  }
}

///|
pub impl @ms.PromptModule for OsModule with name(_self) -> String {
  "os"
}

///|
pub impl @ms.PromptModule for OsModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for OsModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let (name, version) = detect_os()
  guard not(name.is_empty()) else { return Skipped("OS not detected") }

  let symbol = get_os_symbol(name)
  let vars : Map[String, String] = {
    "symbol": symbol,
    "name": name,
    "type": name,
    "style": self.style,
  }

  if not(version.is_empty()) {
    vars["version"] = @exec.add_v_prefix(version)
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
async fn detect_os() -> (String, String) {
  let content = @fs.read_file_to_string("/etc/os-release") catch {
    _ => return (get_uname(), "")
  }

  let mut name = ""
  let mut version = ""
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("ID=") {
      name = strip_quotes(s["ID=".length():].to_string())
    } else if s.has_prefix("VERSION_ID=") {
      version = strip_quotes(s["VERSION_ID=".length():].to_string())
    }
  }

  if name.is_empty() {
    (get_uname(), "")
  } else {
    (name, version)
  }
}

///|
fn strip_quotes(s : String) -> String {
  if s.length() >= 2 && s.has_prefix("\"") && s.has_suffix("\"") {
    s[1:s.length() - 1].to_string()
  } else {
    s
  }
}

///|
async fn get_uname() -> String {
  let output = @exec.exec_cmd("uname", ["-s"])
  if not(output.is_empty()) {
    output.to_lower()
  } else {
    ""
  }
}

///|
fn get_os_symbol(name : String) -> String {
  match name {
    "arch" | "cachyos" | "artix" => "🎗️ "
    "alpine" => "🏔️ "
    "debian" => "🌀 "
    "ubuntu" => "🎯 "
    "fedora" | "nobara" => "🎩 "
    "centos" | "almalinux" | "rocky" => "💠 "
    "nixos" => "❄️ "
    "gentoo" => "🗜️ "
    "opensuse" | "opensuse-leap" | "opensuse-tumbleweed" | "suse" => "🦎 "
    "manjaro" => "🥭 "
    "pop" => "🍭 "
    "void" => " "
    "raspbian" => "🍓 "
    "kali" => "🐉 "
    "mint" => "🌿 "
    "endeavouros" => "🚀 "
    "garuda" => "🦅 "
    "darwin" | "macos" => "🍎 "
    "freebsd" => "😈 "
    "android" => "🤖 "
    "linux" => "🐧 "
    "windows" => "🪟 "
    _ => "🐧 "
  }
}
