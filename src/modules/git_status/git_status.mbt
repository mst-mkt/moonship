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
) -> @ms.ModuleOutput? {
  let config = ctx.config.get_module("git_status")
  guard not(config.disabled) else { return None }
  guard ctx.get_repo() is Some(repo) else { return None }

  let (staged, modified, untracked) = repo.get_status()

  let status = build_status_string([
    (staged, config.get_prop("staged")),
    (modified, config.get_prop("modified")),
    (untracked, config.get_prop("untracked")),
  ])
  guard not(status.is_empty()) else { return None }

  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = { "all_status": status }
  let segments = @ms.format_string(config.format, vars, style)

  Some(@ms.ModuleOutput::new(segments))
}

///|
fn build_status_string(counts : Array[(Int, String)]) -> String {
  counts
  .iter()
  .filter_map(fn(pair) {
    let (count, symbol) = pair
    match count {
      0 => None
      1 => Some(symbol)
      _ => Some("\{symbol}\{count}")
    }
  })
  .collect()
  .join("")
}
