///|
pub struct GitStatusModule {
  disabled : Bool
  format : String
  style : String
  staged : String
  modified : String
  untracked : String
}

///|
pub fn GitStatusModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "git_status",
  ),
) -> GitStatusModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    staged: config.get_prop("staged", default="+"),
    modified: config.get_prop("modified", default="!"),
    untracked: config.get_prop("untracked", default="?"),
  }
}

///|
pub fn GitStatusModule::from_config(
  config : @config.Config,
) -> GitStatusModule {
  GitStatusModule::new(config=config.get_module("git_status"))
}

///|
pub impl @ms.PromptModule for GitStatusModule with name(_self) -> String {
  "git_status"
}

///|
pub impl @ms.PromptModule for GitStatusModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let (staged, modified, untracked) = repo.get_status()

  let all_status = build_status_string([
    (staged, self.staged),
    (modified, self.modified),
    (untracked, self.untracked),
  ])
  guard not(all_status.is_empty()) else { return Skipped("no changes") }

  let style = @terminal.parse_style(self.style)
  let vars : Map[String, String] = {
    "all_status": all_status,
    "staged": format_count(staged, self.staged),
    "modified": format_count(modified, self.modified),
    "untracked": format_count(untracked, self.untracked),
    "style": self.style,
  }
  let segments = @ms.format_string(self.format, vars, style)

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
