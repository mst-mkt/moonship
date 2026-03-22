///|
pub struct ModuleTable(Map[String, @toml.TomlValue])

///|
pub struct Config {
  format : String
  scan_timeout : Int
  command_timeout : Int
  cache_ttl : Int
  add_newline : Bool
  raw_modules : Map[String, ModuleTable]
}

///|
pub fn Config::default() -> Config {
  {
    format: "$all",
    scan_timeout: 30,
    command_timeout: 500,
    cache_ttl: 5000,
    add_newline: true,
    raw_modules: {},
  }
}

///|
pub fn Config::get_raw_module(self : Config, name : String) -> ModuleTable? {
  self.raw_modules.get(name)
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

  let raw_modules : Map[String, ModuleTable] = {}

  table.each(fn(name, mod_value) {
    guard mod_value is TomlTable(mod_table) else { return }
    raw_modules[name] = ModuleTable(mod_table)
  })

  { format, scan_timeout, command_timeout, cache_ttl, add_newline, raw_modules }
}

///|
/// Convert a Config to a TOML string representation.
pub fn Config::to_toml(self : Config) -> String {
  let header = [
    "format = \{quote(self.format)}",
    "scan_timeout = \{self.scan_timeout}",
    "command_timeout = \{self.command_timeout}",
    "cache_ttl = \{self.cache_ttl}",
    "add_newline = \{self.add_newline}",
  ].join("\n")

  let module_names = self.raw_modules.keys().collect()
  module_names.sort()

  let sections = module_names
    .iter()
    .filter_map(fn(name) {
      self.raw_modules
      .get(name)
      .map(fn(table) { raw_module_to_toml(name, table) })
    })
    .collect()
    .join("")

  header + "\n" + sections
}

///|
fn raw_module_to_toml(name : String, table : ModuleTable) -> String {
  let lines : Array[String] = ["\n[\{name}]"]

  let keys = table.0.keys().collect()
  keys.sort()

  for key in keys {
    match table.0.get(key) {
      Some(TomlString(s)) => lines.push("\{key} = \{quote(s)}")
      Some(TomlInteger(n)) => lines.push("\{key} = \{n}")
      Some(TomlBoolean(b)) => lines.push("\{key} = \{b}")
      Some(TomlFloat(f)) => lines.push("\{key} = \{f}")
      Some(TomlArray(arr)) => {
        let items = arr
          .iter()
          .filter_map(fn(v) {
            match v {
              TomlString(s) => Some(quote(s))
              _ => None
            }
          })
          .collect()
          .join(", ")
        lines.push("\{key} = [\{items}]")
      }
      _ => ()
    }
  }

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
pub fn get_toml_string(table : ModuleTable, key : String) -> String? {
  match table.0.get(key) {
    Some(TomlString(s)) => Some(s)
    _ => None
  }
}

///|
pub fn get_toml_int(table : ModuleTable, key : String) -> Int? {
  match table.0.get(key) {
    Some(TomlInteger(n)) => Some(n.to_int())
    _ => None
  }
}

///|
pub fn get_toml_bool(table : ModuleTable, key : String) -> Bool? {
  match table.0.get(key) {
    Some(TomlBoolean(b)) => Some(b)
    _ => None
  }
}

///|
pub fn get_toml_string_array(
  table : ModuleTable,
  key : String,
) -> Array[String]? {
  match table.0.get(key) {
    Some(TomlArray(arr)) => {
      let result : Array[String] = []

      for item in arr {
        match item {
          TomlString(s) => result.push(s)
          _ => ()
        }
      }

      Some(result)
    }
    _ => None
  }
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
