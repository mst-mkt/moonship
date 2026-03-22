///|
pub struct GitBranchModule {
  disabled : Bool
  format : String
  style : String
  truncation_length : Int
  truncation_symbol : String
  symbol : String
  only_attached : Bool
  ignore_branches : Array[String]
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
    truncation_symbol: config.get_prop("truncation_symbol", default="…"),
    symbol: config.get_prop("symbol", default=" "),
    only_attached: config.get_prop("only_attached") == "true",
    ignore_branches: parse_string_list(config.get_prop("ignore_branches")),
  }
}

///|
pub fn GitBranchModule::from_config(config : @config.Config) -> GitBranchModule {
  GitBranchModule::new(config=config.get_module("git_branch"))
}

///|
pub impl @ms.PromptModule for GitBranchModule with name(_self) -> String {
  "git_branch"
}

///|
pub impl @ms.PromptModule for GitBranchModule with is_async(_self) -> Bool {
  false
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
  self.render_branch(raw_branch, is_detached, commit_hash)
}

///|
fn GitBranchModule::render_branch(
  self : GitBranchModule,
  raw_branch : String,
  is_detached : Bool,
  commit_hash : String,
) -> @ms.ModuleResult {
  let branch = if is_detached {
    guard not(self.only_attached) else { return Skipped("detached HEAD") }
    guard not(commit_hash.is_empty()) else {
      return Skipped("detached HEAD with no commit")
    }
    "(\{commit_hash})"
  } else {
    raw_branch
  }

  guard not(self.ignore_branches.contains(branch)) else {
    return Skipped("branch in ignore list")
  }

  let display_branch = if branch.length() > self.truncation_length {
    branch[:self.truncation_length].to_string() + self.truncation_symbol
  } else {
    branch
  }

  let vars : Map[String, String] = {
    "branch": display_branch,
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
fn parse_string_list(s : String) -> Array[String] {
  if s.is_empty() {
    return []
  }

  s
  .split(",")
  .map(fn(sv) { sv.to_string() })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
}
