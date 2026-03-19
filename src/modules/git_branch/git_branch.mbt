///|
pub struct GitBranchModule {}

///|
pub fn GitBranchModule::new() -> GitBranchModule {
  GitBranchModule::{  }
}

///|
pub impl @ms.PromptModule for GitBranchModule with name(_self) -> String {
  "git_branch"
}

///|
pub impl @ms.PromptModule for GitBranchModule with execute(
  _self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  let config = ctx.config.get_module("git_branch")
  guard not(config.disabled) else { return Disabled }
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

  let max_len = config.get_int_prop("truncation_length", default=20)
  let display_branch = if branch.length() > max_len {
    branch[:max_len].to_string() + "…"
  } else {
    branch
  }

  let symbol = config.get_prop("symbol", default=" ")
  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = {
    "branch": display_branch,
    "symbol": symbol,
    "style": config.style,
  }
  let segments = @ms.format_string(config.format, vars, style)

  Output(@ms.ModuleOutput::new(segments))
}
