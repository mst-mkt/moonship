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
pub fn FossilBranchModule::from_table(
  table : @config.ModuleTable,
) -> FossilBranchModule {
  let d = FossilBranchModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn FossilBranchModule::from_config(
  config : @config.Config,
) -> FossilBranchModule {
  match config.get_raw_module("fossil_branch") {
    Some(table) => FossilBranchModule::from_table(table)
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
  @fs.path_exists("\{cwd}/.fslckout") || @fs.path_exists("\{cwd}/_FOSSIL_")
}

///|
pub fn FossilBranchModule::schema() -> @config.ModuleSchema {
  let d = FossilBranchModule::default()
  {
    name: "fossil_branch",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
