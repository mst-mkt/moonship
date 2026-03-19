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
) -> @ms.ModuleOutput? {
  let config = ctx.config.get_module("git_branch")
  guard not(config.disabled) else { return None }
  guard ctx.git_info is Some(info) else { return None }

  let branch = if info.is_detached {
    guard not(info.commit_hash.is_empty()) else { return None }
    "(\{info.commit_hash})"
  } else {
    info.branch
  }

  let max_len = config.get_int_prop("truncation_length", default=20)
  let display_branch = if branch.length() > max_len {
    branch[:max_len].to_string() + "…"
  } else {
    branch
  }

  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = { "branch": display_branch }
  let segments = @ms.format_string(config.format, vars, style)

  Some(@ms.ModuleOutput::new(segments))
}
