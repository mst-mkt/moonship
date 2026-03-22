///|
pub struct OCamlModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  global_switch_indicator : String
  local_switch_indicator : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn OCamlModule::default() -> OCamlModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )(\\($switch_indicator$switch_name\\) )]($style)",
    style: "bold yellow",
    symbol: "🐫 ",
    global_switch_indicator: "",
    local_switch_indicator: "*",
    detect_files: ["dune", "dune-project", "jbuild", "jbuild-ignore", ".merlin"],
    detect_folders: ["_opam", "esy.lock"],
    detect_extensions: [".opam", ".ml", ".mli", ".re", ".rei"],
  }
}

///|
pub fn OCamlModule::from_table(table : @config.ModuleTable) -> OCamlModule {
  let d = OCamlModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    global_switch_indicator: table
    .get_string("global_switch_indicator")
    .unwrap_or(d.global_switch_indicator),
    local_switch_indicator: table
    .get_string("local_switch_indicator")
    .unwrap_or(d.local_switch_indicator),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn OCamlModule::from_config(config : @config.Config) -> OCamlModule {
  match config.get_raw_module("ocaml") {
    Some(table) => OCamlModule::from_table(table)
    None => OCamlModule::default()
  }
}

///|
pub impl @ms.PromptModule for OCamlModule with name(_self) -> String {
  "ocaml"
}

///|
pub impl @ms.PromptModule for OCamlModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for OCamlModule with execute(
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
    return Skipped("no OCaml project detected")
  }

  let version = @exec.exec_cmd("ocaml", ["-vnum"])
  guard not(version.is_empty()) else { return Skipped("ocaml not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
    "symbol": self.symbol,
    "style": self.style,
  }

  let switch_output = @exec.exec_cmd("opam", ["switch", "show", "--safe"])
  if not(switch_output.is_empty()) {
    let (indicator, name) = parse_opam_switch(
      switch_output,
      self.global_switch_indicator,
      self.local_switch_indicator,
    )
    vars["switch_indicator"] = indicator
    vars["switch_name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_opam_switch(
  switch : String,
  global_indicator : String,
  local_indicator : String,
) -> (String, String) {
  if switch.has_prefix("/") {
    let init : (Int?, Int) = (None, 0)

    let name = match
      switch
      .iter()
      .fold(init~, fn(acc, ch) {
        let (result, i) = acc
        (if ch == '/' { Some(i) } else { result }, i + 1)
      }).0 {
      Some(last) => switch[last + 1:].to_string()
      None => switch
    }
    (local_indicator, name)
  } else {
    (global_indicator, switch)
  }
}

///|
pub fn OCamlModule::schema() -> @config.ModuleSchema {
  let d = OCamlModule::default()
  {
    name: "ocaml",
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
        name: "global_switch_indicator",
        field_type: @config.FString,
        default_value: d.global_switch_indicator,
      },
      {
        name: "local_switch_indicator",
        field_type: @config.FString,
        default_value: d.local_switch_indicator,
      },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
