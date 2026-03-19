///|
pub struct GitStatusModule {}

///|
pub fn GitStatusModule::new() -> GitStatusModule {
  GitStatusModule::{  }
}

///|
pub impl @ms.PromptModule for GitStatusModule with name(_self) -> String {
  "git_status"
}

///|
pub impl @ms.PromptModule for GitStatusModule with execute(
  _self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  let config = ctx.config.get_module("git_status")
  guard not(config.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let (staged, modified, untracked) = repo.get_status()

  let staged_sym = config.get_prop("staged", default="+")
  let modified_sym = config.get_prop("modified", default="!")
  let untracked_sym = config.get_prop("untracked", default="?")

  let all_status = build_status_string([
    (staged, staged_sym),
    (modified, modified_sym),
    (untracked, untracked_sym),
  ])
  guard not(all_status.is_empty()) else { return Skipped("no changes") }

  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = {
    "all_status": all_status,
    "staged": format_count(staged, staged_sym),
    "modified": format_count(modified, modified_sym),
    "untracked": format_count(untracked, untracked_sym),
    "style": config.style,
  }
  let segments = @ms.format_string(config.format, vars, style)

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn format_count(count : Int, symbol : String) -> String {
  if count > 0 {
    symbol
  } else {
    ""
  }
}

///|
fn build_status_string(counts : Array[(Int, String)]) -> String {
  counts
  .iter()
  .map(fn(pair) { format_count(pair.0, pair.1) })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
  .join("")
}
