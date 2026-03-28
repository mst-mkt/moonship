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
    JStr(s) => escape_string(s)
    JNum(n) =>
      if n == n.to_int().to_double() {
        n.to_int().to_string()
      } else {
        n.to_string()
      }
    JBool(b) => b.to_string()
    JArr(items) => {
      if items.is_empty() {
        return "[]"
      }

      let parts = items
        .iter()
        .map(fn(item) {
          "\{pad(depth + 1, indent)}\{stringify_val(item, depth + 1, indent)}"
        })
        .collect()
        .join(",\n")

      "[\n\{parts}\n\{pad(depth, indent)}]"
    }
    JObj(entries) => {
      if entries.is_empty() {
        return "{}"
      }

      let parts = entries
        .iter()
        .map(fn(pair) {
          let (key, val) = pair
          "\{pad(depth + 1, indent)}\{escape_string(key)}: \{stringify_val(val, depth + 1, indent)}"
        })
        .collect()
        .join(",\n")

      "{\n\{parts}\n\{pad(depth, indent)}}"
    }
  }
}

///|
fn pad(depth : Int, indent : Int) -> String {
  String::make(depth * indent, ' ')
}

///|
pub fn generate_json_schema(modules : Array[ModuleSchema]) -> String {
  let module_entries = modules
    .iter()
    .map(fn(mod_schema) { (mod_schema.name, module_schema_to_jval(mod_schema)) })
    .collect()

  let prop_entries : Array[(String, JVal)] = [
    ("format", schema_prop("string", JStr("$all"))),
    ("scan_timeout", schema_prop("integer", JNum(30.0))),
    ("command_timeout", schema_prop("integer", JNum(500.0))),
    ("cache_ttl", schema_prop("integer", JNum(5000.0))),
    ("add_newline", schema_prop("boolean", JBool(true))),
    ..module_entries,
  ]

  let top_entries : Array[(String, JVal)] = [
    ("$schema", JStr("http://json-schema.org/draft-07/schema#")),
    ("type", JStr("object")),
    ("properties", JObj(prop_entries)),
  ]

  JObj(top_entries).stringify(indent=2)
}

///|
fn module_schema_to_jval(mod_schema : ModuleSchema) -> JVal {
  let custom_fields = mod_schema.fields
    .iter()
    .filter(fn(field) { field.name != "disabled" && field.name != "async" })
    .map(fn(field) { (field.name, field_to_jval(field)) })
    .collect()

  let field_entries : Array[(String, JVal)] = [
    ("disabled", schema_prop("boolean", JBool(false))),
    ("async", schema_prop("boolean", JBool(false))),
    ..custom_fields,
  ]

  JObj([("type", JStr("object")), ("properties", JObj(field_entries))])
}

///|
fn field_to_jval(field : FieldSchema) -> JVal {
  match field.field_type {
    FString => schema_prop("string", JStr(field.default_value))
    FInt => {
      let n = @strconv.parse_int(field.default_value) catch { _ => 0 }
      schema_prop("integer", JNum(n.to_double()))
    }
    FBool => schema_prop("boolean", JBool(field.default_value == "true"))
    FFloat => {
      let f = @strconv.parse_double(field.default_value) catch { _ => 0.0 }
      schema_prop("number", JNum(f))
    }
    FStringArray => {
      let items : Array[JVal] = if field.default_value.is_empty() {
        []
      } else {
        field.default_value
        .split(",")
        .map(fn(s) { JStr(s.trim(chars=" ").to_string()) })
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
fn schema_prop(json_type : String, default_val : JVal) -> JVal {
  JObj([("type", JStr(json_type)), ("default", default_val)])
}
