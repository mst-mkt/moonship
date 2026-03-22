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
pub fn OCamlModule::from_toml_table(table : @config.ModuleTable) -> OCamlModule {
  let d = OCamlModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    global_switch_indicator: @config.get_toml_string(
      table, "global_switch_indicator",
    ).unwrap_or(d.global_switch_indicator),
    local_switch_indicator: @config.get_toml_string(
      table, "local_switch_indicator",
    ).unwrap_or(d.local_switch_indicator),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_folders: @config.get_toml_string_array(table, "detect_folders").unwrap_or(
      d.detect_folders,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn OCamlModule::from_config(config : @config.Config) -> OCamlModule {
  match config.get_raw_module("ocaml") {
    Some(table) => OCamlModule::from_toml_table(table)
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
    let mut last = -1

    for i = 0; i < switch.length(); i = i + 1 {
      if switch[i] == '/' {
        last = i
      }
    }

    let name = if last >= 0 { switch[last + 1:].to_string() } else { switch }
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
