///|
pub struct RakuModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn RakuModule::default() -> RakuModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version-$vm_version )]($style)",
    style: "149 bold",
    symbol: "🦋 ",
    detect_files: ["META6.json"],
    detect_extensions: [".p6", ".pm6", ".pod6", ".raku", ".rakumod"],
    detect_folders: [],
  }
}

///|
pub fn RakuModule::from_table(table : @config.ModuleTable) -> RakuModule {
  let d = RakuModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn RakuModule::from_config(config : @config.Config) -> RakuModule {
  match config.get_raw_module("raku") {
    Some(table) => RakuModule::from_table(table)
    None => RakuModule::default()
  }
}

///|
pub impl @ms.PromptModule for RakuModule with name(_self) -> String {
  "raku"
}

///|
pub impl @ms.PromptModule for RakuModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for RakuModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no Raku project detected")
  }

  let output = @exec.exec_cmd_full("raku", ["--version"])
  guard not(output.is_empty()) else { return Skipped("raku not found") }

  let (version, vm_version) = parse_raku_version(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse raku version")
  }

  let vars : Map[String, String] = {
    "version": version,
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(vm_version.is_empty()) {
    vars["vm_version"] = vm_version
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_raku_version(output : String) -> (String, String) {
  output
  .split("\n")
  .fold(init=("", ""), fn(acc, line) {
    let s = line.to_string()
    let (ver, vm) = acc

    if s.has_prefix("This is Rakudo") {
      let parts = s.split(" ").map(fn(p) { p.to_string() }).collect()
      (if parts.length() >= 5 { parts[4] } else { ver }, vm)
    } else if s.contains("MoarVM version") {
      let parts = s.split(" ").map(fn(p) { p.to_string() }).collect()
      let new_vm = parts
        .iter()
        .fold(init=("", false, false), fn(state, p) {
          let (result, take_next, done) = state
          if done {
            state
          } else if take_next {
            (p, false, true)
          } else if p == "version" {
            (result, true, false)
          } else {
            state
          }
        }).0
      (ver, if new_vm.is_empty() { vm } else { new_vm })
    } else {
      (ver, vm)
    }
  })
}

///|
pub fn RakuModule::schema() -> @config.ModuleSchema {
  let d = RakuModule::default()
  {
    name: "raku",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
    ],
  }
}
