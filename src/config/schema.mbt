///|
pub(all) enum FieldType {
  FString
  FInt
  FBool
  FFloat
  FStringArray
}

///|
pub(all) struct FieldSchema {
  name : String
  field_type : FieldType
  default_value : String
}

///|
pub(all) struct ModuleSchema {
  name : String
  fields : Array[FieldSchema]
}

///|
/// Internal JSON value type for schema construction.
/// Used because MoonBit's builtin Json enum is read-only from external packages.
priv enum JVal {
  JStr(String)
  JNum(Double)
  JBool(Bool)
  JNull
  JArr(Array[JVal])
  JObj(Array[(String, JVal)])
}

///|
fn JVal::stringify(self : JVal, indent? : Int = 0) -> String {
  stringify_val(self, 0, indent)
}

///|
fn stringify_val(v : JVal, depth : Int, indent : Int) -> String {
  match v {
    JStr(s) => json_escape(s)
    JNum(n) =>
      if n == n.to_int().to_double() {
        n.to_int().to_string()
      } else {
        n.to_string()
      }
    JBool(b) => b.to_string()
    JNull => "null"
    JArr(items) => {
      if items.is_empty() {
        return "[]"
      }

      let parts = items
        .iter()
        .map(fn(item) {
          pad(depth + 1, indent) + stringify_val(item, depth + 1, indent)
        })
        .collect()
        .join(",\n")

      "[\n" + parts + "\n" + pad(depth, indent) + "]"
    }
    JObj(entries) => {
      if entries.is_empty() {
        return "{}"
      }

      let parts = entries
        .iter()
        .map(fn(pair) {
          let (key, val) = pair
          pad(depth + 1, indent) +
          json_escape(key) +
          ": " +
          stringify_val(val, depth + 1, indent)
        })
        .collect()
        .join(",\n")

      "{\n" + parts + "\n" + pad(depth, indent) + "}"
    }
  }
}

///|
fn pad(depth : Int, indent : Int) -> String {
  let buf = StringBuilder::new()

  for _ in 0..<(depth * indent) {
    buf.write_char(' ')
  }

  buf.to_string()
}

///|
fn json_escape(s : String) -> String {
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

///|
pub fn generate_json_schema(modules : Array[ModuleSchema]) -> String {
  let top_entries : Array[(String, JVal)] = []

  top_entries.push(("$schema", JStr("http://json-schema.org/draft-07/schema#")))
  top_entries.push(("type", JStr("object")))

  let prop_entries : Array[(String, JVal)] = []
  prop_entries.push(("format", typed_prop("string", default_str="$all")))
  prop_entries.push(("scan_timeout", typed_prop("integer", default_int=30)))
  prop_entries.push(("command_timeout", typed_prop("integer", default_int=500)))
  prop_entries.push(("cache_ttl", typed_prop("integer", default_int=5000)))
  prop_entries.push(("add_newline", typed_prop("boolean", default_bool=true)))

  for mod_schema in modules {
    prop_entries.push((mod_schema.name, module_schema_to_jval(mod_schema)))
  }

  top_entries.push(("properties", JObj(prop_entries)))
  JObj(top_entries).stringify(indent=2)
}

///|
fn module_schema_to_jval(mod_schema : ModuleSchema) -> JVal {
  let field_entries : Array[(String, JVal)] = []

  field_entries.push(("async", typed_prop("boolean", default_bool=false)))

  for field in mod_schema.fields {
    field_entries.push((field.name, field_to_jval(field)))
  }

  JObj([("type", JStr("object")), ("properties", JObj(field_entries))])
}

///|
fn field_to_jval(field : FieldSchema) -> JVal {
  match field.field_type {
    FString => typed_prop("string", default_str=field.default_value)
    FInt => {
      let n = @strconv.parse_int(field.default_value) catch { _ => 0 }
      typed_prop("integer", default_int=n)
    }
    FBool => typed_prop("boolean", default_bool=field.default_value == "true")
    FFloat => {
      let f = @strconv.parse_double(field.default_value) catch { _ => 0.0 }
      typed_prop("number", default_float=f)
    }
    FStringArray => {
      let items : Array[JVal] = if field.default_value.is_empty() {
        []
      } else {
        field.default_value
        .split(",")
        .map(fn(s) { JStr(s.to_string().trim(chars=" ").to_string()) })
        .collect()
      }

      JObj([
        ("type", JStr("array")),
        ("items", JObj([("type", JStr("string"))])),
        ("default", JArr(items)),
      ])
    }
  }
}

///|
fn typed_prop(
  json_type : String,
  default_str? : String = "",
  default_int? : Int = 0,
  default_bool? : Bool = false,
  default_float? : Double = 0.0,
) -> JVal {
  let default_val : JVal = match json_type {
    "string" => JStr(default_str)
    "integer" => JNum(default_int.to_double())
    "boolean" => JBool(default_bool)
    "number" => JNum(default_float)
    _ => JNull
  }

  JObj([("type", JStr(json_type)), ("default", default_val)])
}
