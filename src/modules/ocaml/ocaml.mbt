///|
pub struct OCamlModule {
  disabled : Bool
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
pub fn OCamlModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("ocaml"),
) -> OCamlModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐫 "),
    global_switch_indicator: config.get_prop(
      "global_switch_indicator",
      default="",
    ),
    local_switch_indicator: config.get_prop(
      "local_switch_indicator",
      default="*",
    ),
    detect_files: ["dune", "dune-project", "jbuild", "jbuild-ignore", ".merlin"],
    detect_folders: ["_opam", "esy.lock"],
    detect_extensions: [".opam", ".ml", ".mli", ".re", ".rei"],
  }
}

///|
pub fn OCamlModule::from_config(config : @config.Config) -> OCamlModule {
  OCamlModule::new(config=config.get_module("ocaml"))
}

///|
pub impl @ms.PromptModule for OCamlModule with name(_self) -> String {
  "ocaml"
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
