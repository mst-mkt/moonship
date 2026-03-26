///|
pub struct OsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbols : Map[String, String]
}

///|
pub fn OsModule::default() -> OsModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol]($style)",
    style: "bold white",
    symbols: {},
  }
}

///|
pub fn OsModule::from_table(table : @config.ModuleTable) -> OsModule {
  let d = OsModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbols: parse_os_symbols(table),
  }
}

///|
pub fn OsModule::from_config(config : @config.Config) -> OsModule {
  match config.get_raw_module("os") {
    Some(table) => OsModule::from_table(table)
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

  let symbol = match self.symbols.get(name) {
    Some(custom) => custom
    None => get_os_symbol(name)
  }
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

  let (name, version) = content
    .split("\n")
    .fold(init=("", ""), fn(acc, line) {
      let s = line.to_string()
      let (n, v) = acc

      if s.has_prefix("ID=") {
        (strip_quotes(s["ID=".length():].to_string()), v)
      } else if s.has_prefix("VERSION_ID=") {
        (n, strip_quotes(s["VERSION_ID=".length():].to_string()))
      } else {
        (n, v)
      }
    })

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
fn parse_os_symbols(table : @config.ModuleTable) -> Map[String, String] {
  match table.0.get("symbols") {
    Some(@config.CTable(sym_table)) =>
      sym_table
      .iter()
      .fold(init=(Map::new() : Map[String, String]), fn(acc, pair) {
        match pair.1 {
          @config.CString(val) => {
            // Starship uses PascalCase OS names, moonship uses lowercase
            let key = pair.0.to_lower()
            acc[key] = val
            acc
          }
          _ => acc
        }
      })
    _ => {}
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

///|
pub fn OsModule::schema() -> @config.ModuleSchema {
  let d = OsModule::default()
  {
    name: "os",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
    ],
  }
}
