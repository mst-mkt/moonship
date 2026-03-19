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
  guard ctx.git_info is Some(info) else { return None }

  let status = build_status_string([
    (info.ahead, config.get_prop("ahead")),
    (info.behind, config.get_prop("behind")),
    (info.staged, config.get_prop("staged")),
    (info.modified, config.get_prop("modified")),
    (info.untracked, config.get_prop("untracked")),
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
