///|
pub(all) enum ConfigValue {
  CString(String)
  CInt(Int)
  CBool(Bool)
  CFloat(Double)
  CArray(Array[ConfigValue])
  CTable(Map[String, ConfigValue])
}

///|
pub struct ModuleTable(Map[String, ConfigValue])

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
/// Parse a TOML string into a Config.
pub fn Config::from_toml(toml_str : String) -> Config raise {
  let value = @toml.parse(toml_str)
  guard value is TomlTable(table) else {
    raise Failure::Failure("expected TOML table at root")
  }

  let config_table = toml_table_to_config(table)
  parse_config_table(config_table)
}

///|
fn parse_config_table(table : Map[String, ConfigValue]) -> Config {
  let default = Config::default()

  let format = get_cv_string(table, "format").unwrap_or(default.format)
  let scan_timeout = get_cv_int(table, "scan_timeout").unwrap_or(
    default.scan_timeout,
  )
  let command_timeout = get_cv_int(table, "command_timeout").unwrap_or(
    default.command_timeout,
  )
  let cache_ttl = get_cv_int(table, "cache_ttl").unwrap_or(default.cache_ttl)
  let add_newline = get_cv_bool(table, "add_newline").unwrap_or(
    default.add_newline,
  )

  let raw_modules : Map[String, ModuleTable] = {}

  table.each(fn(name, value) {
    guard value is CTable(mod_table) else { return }
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
      Some(CString(s)) => lines.push("\{key} = \{quote(s)}")
      Some(CInt(n)) => lines.push("\{key} = \{n}")
      Some(CBool(b)) => lines.push("\{key} = \{b}")
      Some(CFloat(f)) => lines.push("\{key} = \{f}")
      Some(CArray(arr)) => {
        let items = arr
          .iter()
          .map(fn(v) { config_value_to_toml_literal(v) })
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
fn config_value_to_toml_literal(v : ConfigValue) -> String {
  match v {
    CString(s) => quote(s)
    CInt(n) => n.to_string()
    CBool(b) => b.to_string()
    CFloat(f) => f.to_string()
    CArray(_) | CTable(_) => "\"\""
  }
}

// --- Public helpers for modules ---

///|
pub fn get_toml_string(table : ModuleTable, key : String) -> String? {
  match table.0.get(key) {
    Some(CString(s)) => Some(s)
    _ => None
  }
}

///|
pub fn get_toml_int(table : ModuleTable, key : String) -> Int? {
  match table.0.get(key) {
    Some(CInt(n)) => Some(n)
    _ => None
  }
}

///|
pub fn get_toml_bool(table : ModuleTable, key : String) -> Bool? {
  match table.0.get(key) {
    Some(CBool(b)) => Some(b)
    _ => None
  }
}

///|
pub fn get_toml_string_array(
  table : ModuleTable,
  key : String,
) -> Array[String]? {
  match table.0.get(key) {
    Some(CArray(arr)) => {
      let result : Array[String] = []

      for item in arr {
        match item {
          CString(s) => result.push(s)
          _ => ()
        }
      }

      Some(result)
    }
    _ => None
  }
}

///|
/// Parse a JSON/JSONC/JSON5 string into a Config.
pub fn Config::from_json(json_str : String) -> Config raise {
  let value = @json5.parse(json_str)
  guard value is Object(table) else {
    raise Failure::Failure("expected JSON object at root")
  }

  let config_table = json_table_to_config(table)
  parse_config_table(config_table)
}

// --- JSON conversion ---

///|
fn json_to_config(v : Json) -> ConfigValue {
  match v {
    String(s) => CString(s)
    Number(n, ..) =>
      if n == n.to_int().to_double() {
        CInt(n.to_int())
      } else {
        CFloat(n)
      }
    True => CBool(true)
    False => CBool(false)
    Array(arr) => CArray(arr.map(json_to_config))
    Object(obj) => CTable(json_table_to_config(obj))
    Null => CString("")
  }
}

///|
fn json_table_to_config(table : Map[String, Json]) -> Map[String, ConfigValue] {
  let result : Map[String, ConfigValue] = {}

  table.each(fn(key, value) {
    if not(value is Null) {
      result[key] = json_to_config(value)
    }
  })

  result
}

// --- TOML conversion ---

///|
fn toml_to_config(v : @toml.TomlValue) -> ConfigValue {
  match v {
    TomlString(s) => CString(s)
    TomlInteger(n) => CInt(n.to_int())
    TomlBoolean(b) => CBool(b)
    TomlFloat(f) => CFloat(f)
    TomlArray(arr) => CArray(arr.map(toml_to_config))
    TomlTable(t) => CTable(toml_table_to_config(t))
    _ => CString("")
  }
}

///|
fn toml_table_to_config(
  table : Map[String, @toml.TomlValue],
) -> Map[String, ConfigValue] {
  let result : Map[String, ConfigValue] = {}

  table.each(fn(key, value) { result[key] = toml_to_config(value) })

  result
}

// --- Private helpers for top-level config parsing ---

///|
fn get_cv_string(table : Map[String, ConfigValue], key : String) -> String? {
  match table.get(key) {
    Some(CString(s)) => Some(s)
    _ => None
  }
}

///|
fn get_cv_int(table : Map[String, ConfigValue], key : String) -> Int? {
  match table.get(key) {
    Some(CInt(n)) => Some(n)
    _ => None
  }
}

///|
fn get_cv_bool(table : Map[String, ConfigValue], key : String) -> Bool? {
  match table.get(key) {
    Some(CBool(b)) => Some(b)
    _ => None
  }
}
