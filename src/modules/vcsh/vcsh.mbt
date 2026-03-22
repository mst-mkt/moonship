///|
pub struct VcshModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn VcshModule::default() -> VcshModule {
  {
    disabled: false,
    async_render: false,
    format: "vcsh [$symbol$repo]($style) ",
    style: "bold yellow",
    symbol: "",
  }
}

///|
pub fn VcshModule::from_toml_table(table : @config.ModuleTable) -> VcshModule {
  let d = VcshModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn VcshModule::from_config(config : @config.Config) -> VcshModule {
  match config.get_raw_module("vcsh") {
    Some(table) => VcshModule::from_toml_table(table)
    None => VcshModule::default()
  }
}

///|
pub impl @ms.PromptModule for VcshModule with name(_self) -> String {
  "vcsh"
}

///|
pub impl @ms.PromptModule for VcshModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for VcshModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let repo = @sys.get_env_var("VCSH_REPO_NAME").unwrap_or("")
  guard not(repo.is_empty()) else { return Skipped("not in vcsh repo") }

  let vars : Map[String, String] = {
    "repo": repo,
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
