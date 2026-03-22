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
pub fn ModuleTable::get_string(self : ModuleTable, key : String) -> String? {
  match self.0.get(key) {
    Some(CString(s)) => Some(s)
    _ => None
  }
}

///|
pub fn ModuleTable::get_int(self : ModuleTable, key : String) -> Int? {
  match self.0.get(key) {
    Some(CInt(n)) => Some(n)
    _ => None
  }
}

///|
pub fn ModuleTable::get_bool(self : ModuleTable, key : String) -> Bool? {
  match self.0.get(key) {
    Some(CBool(b)) => Some(b)
    _ => None
  }
}

///|
pub fn ModuleTable::get_float(self : ModuleTable, key : String) -> Double? {
  match self.0.get(key) {
    Some(CFloat(f)) => Some(f)
    _ => None
  }
}

///|
pub fn ModuleTable::get_string_array(
  self : ModuleTable,
  key : String,
) -> Array[String]? {
  match self.0.get(key) {
    Some(CArray(arr)) => {
      guard arr.iter().all(fn(item) { item is CString(_) }) else { return None }

      Some(
        arr
        .iter()
        .filter_map(fn(item) {
          match item {
            CString(s) => Some(s)
            _ => None
          }
        })
        .collect(),
      )
    }
    _ => None
  }
}

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
pub fn Config::from_toml(toml_str : String) -> Config raise {
  let value = @toml.parse(toml_str)
  guard value is TomlTable(table) else {
    raise Failure::Failure("expected TOML table at root")
  }

  parse_config_table(toml_table_to_config(table))
}

///|
pub fn Config::from_json(json_str : String) -> Config raise {
  let value = @json5.parse(json_str)
  guard value is Object(table) else {
    raise Failure::Failure("expected JSON object at root")
  }

  parse_config_table(json_table_to_config(table))
}

///|
fn parse_config_table(table : Map[String, ConfigValue]) -> Config {
  let d = Config::default()
  let t = ModuleTable(table)

  let format = t.get_string("format").unwrap_or(d.format)
  let scan_timeout = t.get_int("scan_timeout").unwrap_or(d.scan_timeout)
  let command_timeout = t
    .get_int("command_timeout")
    .unwrap_or(d.command_timeout)
  let cache_ttl = t.get_int("cache_ttl").unwrap_or(d.cache_ttl)
  let add_newline = t.get_bool("add_newline").unwrap_or(d.add_newline)

  let raw_modules = table
    .iter()
    .fold(init=(Map::new() : Map[String, ModuleTable]), fn(acc, pair) {
      let (name, value) = pair
      match value {
        CTable(mod_table) => acc.set(name, ModuleTable(mod_table))
        _ => ()
      }
      acc
    })

  { format, scan_timeout, command_timeout, cache_ttl, add_newline, raw_modules }
}

///|
pub fn Config::to_toml(self : Config) -> String {
  let header = [
    "format = \{escape_string(self.format)}",
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
      self.raw_modules.get(name).map(fn(table) { module_to_toml(name, table) })
    })
    .collect()
    .join("")

  "\{header}\n\{sections}"
}

///|
fn module_to_toml(name : String, table : ModuleTable) -> String {
  let keys = table.0.keys().collect()
  keys.sort()

  let key_lines = keys
    .iter()
    .filter_map(fn(key) {
      match table.0.get(key) {
        Some(CString(s)) => Some("\{key} = \{escape_string(s)}")
        Some(CInt(n)) => Some("\{key} = \{n}")
        Some(CBool(b)) => Some("\{key} = \{b}")
        Some(CFloat(f)) => Some("\{key} = \{f}")
        Some(CArray(arr)) => {
          let items = arr
            .iter()
            .map(fn(v) { config_value_to_literal(v) })
            .collect()
            .join(", ")
          Some("\{key} = [\{items}]")
        }
        _ => None
      }
    })
    .collect()

  let lines : Array[String] = ["\n[\{name}]", ..key_lines]
  lines.join("\n") + "\n"
}

///|
fn config_value_to_literal(v : ConfigValue) -> String {
  match v {
    CString(s) => escape_string(s)
    CInt(n) => n.to_string()
    CBool(b) => b.to_string()
    CFloat(f) => f.to_string()
    CArray(_) | CTable(_) => "\"\""
  }
}

///|
pub fn escape_string(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('"')

  for ch in s {
    match ch {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(ch)
    }
  }

  buf.write_char('"')
  buf.to_string()
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
    Array(arr) =>
      CArray(
        arr
        .iter()
        .filter(fn(v) { not(v is Null) })
        .map(json_to_config)
        .collect(),
      )
    Object(obj) => CTable(json_table_to_config(obj))
    Null => CString("")
  }
}

///|
fn json_table_to_config(table : Map[String, Json]) -> Map[String, ConfigValue] {
  table
  .iter()
  .filter(fn(pair) { not(pair.1 is Null) })
  .fold(init=(Map::new() : Map[String, ConfigValue]), fn(acc, pair) {
    let (key, value) = pair
    acc[key] = json_to_config(value)
    acc
  })
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
  table
  .iter()
  .fold(init=(Map::new() : Map[String, ConfigValue]), fn(acc, pair) {
    let (key, value) = pair
    acc[key] = toml_to_config(value)
    acc
  })
}
