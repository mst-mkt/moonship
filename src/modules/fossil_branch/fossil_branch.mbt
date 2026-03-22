///|
pub struct FossilBranchModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn FossilBranchModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "fossil_branch",
  ),
) -> FossilBranchModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
  }
}

///|
pub fn FossilBranchModule::from_config(
  config : @config.Config,
) -> FossilBranchModule {
  FossilBranchModule::new(config=config.get_module("fossil_branch"))
}

///|
pub impl @ms.PromptModule for FossilBranchModule with name(_self) -> String {
  "fossil_branch"
}

///|
pub impl @ms.PromptModule for FossilBranchModule with is_async(_self) -> Bool {
  false
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
