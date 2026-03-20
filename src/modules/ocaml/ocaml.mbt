///|
pub struct OCamlModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
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
    detect_files: ["dune", "dune-project", "jbuild", "jbuild-ignore", ".merlin"],
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
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no OCaml project detected")
  }

  let version = @exec.exec_cmd("ocaml", ["-vnum"])
  guard not(version.is_empty()) else { return Skipped("ocaml not found") }

  let vars : Map[String, String] = {
    "version": version,
    "symbol": self.symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
