///|
pub struct FossilBranchModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn FossilBranchModule::default() -> FossilBranchModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$branch]($style) ",
    style: "bold purple",
    symbol: " ",
  }
}

///|
pub fn FossilBranchModule::from_toml_table(
  table : @config.ModuleTable,
) -> FossilBranchModule {
  let d = FossilBranchModule::default()
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
pub fn FossilBranchModule::from_config(
  config : @config.Config,
) -> FossilBranchModule {
  match config.get_raw_module("fossil_branch") {
    Some(table) => FossilBranchModule::from_toml_table(table)
    None => FossilBranchModule::default()
  }
}

///|
pub impl @ms.PromptModule for FossilBranchModule with name(_self) -> String {
  "fossil_branch"
}

///|
pub impl @ms.PromptModule for FossilBranchModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for FossilBranchModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard is_fossil_repo(ctx.cwd) else { return Skipped("not in fossil repo") }

  let branch = @exec.exec_cmd("fossil", ["branch", "current"])
  guard not(branch.is_empty()) else { return Skipped("fossil not found") }

  let vars : Map[String, String] = {
    "branch": branch,
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

///|
fn is_fossil_repo(cwd : String) -> Bool {
  @fs.path_exists(cwd + "/.fslckout") || @fs.path_exists(cwd + "/_FOSSIL_")
}
