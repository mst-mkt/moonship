///|
pub struct GitBranchModule {
  disabled : Bool
  format : String
  style : String
  truncation_length : Int
  symbol : String
}

///|
pub fn GitBranchModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "git_branch",
  ),
) -> GitBranchModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    truncation_length: config.get_int_prop("truncation_length", default=20),
    symbol: config.get_prop("symbol", default=" "),
  }
}

///|
pub fn GitBranchModule::from_config(
  config : @config.Config,
) -> GitBranchModule {
  GitBranchModule::new(config=config.get_module("git_branch"))
}

///|
pub impl @ms.PromptModule for GitBranchModule with name(_self) -> String {
  "git_branch"
}

///|
pub impl @ms.PromptModule for GitBranchModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let (raw_branch, is_detached, commit_hash) = repo.get_branch()

  let branch = if is_detached {
    guard not(commit_hash.is_empty()) else {
      return Skipped("detached HEAD with no commit")
    }
    "(\{commit_hash})"
  } else {
    raw_branch
  }

  let display_branch = if branch.length() > self.truncation_length {
    branch[:self.truncation_length].to_string() + "…"
  } else {
    branch
  }

  let style = @terminal.parse_style(self.style)
  let vars : Map[String, String] = {
    "branch": display_branch,
    "symbol": self.symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(self.format, vars, style)

  Output(@ms.ModuleOutput::new(segments))
}
