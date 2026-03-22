///|
pub struct NixShellModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  impure_msg : String
  pure_msg : String
  unknown_msg : String
  heuristic : Bool
}

///|
pub fn NixShellModule::default() -> NixShellModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$state( \\($name\\))]($style) ",
    style: "bold blue",
    symbol: "❄️  ",
    impure_msg: "impure",
    pure_msg: "pure",
    unknown_msg: "",
    heuristic: false,
  }
}

///|
pub fn NixShellModule::from_toml_table(
  table : @config.ModuleTable,
) -> NixShellModule {
  let d = NixShellModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    impure_msg: @config.get_toml_string(table, "impure_msg").unwrap_or(
      d.impure_msg,
    ),
    pure_msg: @config.get_toml_string(table, "pure_msg").unwrap_or(d.pure_msg),
    unknown_msg: @config.get_toml_string(table, "unknown_msg").unwrap_or(
      d.unknown_msg,
    ),
    heuristic: @config.get_toml_bool(table, "heuristic").unwrap_or(d.heuristic),
  }
}

///|
pub fn NixShellModule::from_config(config : @config.Config) -> NixShellModule {
  match config.get_raw_module("nix_shell") {
    Some(table) => NixShellModule::from_toml_table(table)
    None => NixShellModule::default()
  }
}

///|
pub impl @ms.PromptModule for NixShellModule with name(_self) -> String {
  "nix_shell"
}

///|
pub impl @ms.PromptModule for NixShellModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for NixShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let in_nix = @sys.get_env_var("IN_NIX_SHELL").unwrap_or("")
  let state = if in_nix == "pure" {
    self.pure_msg
  } else if in_nix == "impure" {
    self.impure_msg
  } else if self.heuristic && is_nix_in_path() {
    self.unknown_msg
  } else {
    return Skipped("not in nix shell")
  }

  let name = @sys.get_env_var("name").unwrap_or("")
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "state": state,
    "style": self.style,
  }

  if not(name.is_empty()) {
    vars["name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn is_nix_in_path() -> Bool {
  let path = @sys.get_env_var("PATH").unwrap_or("")
  path.contains("/nix/store")
}
