///|
pub struct GitStatusModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  staged : String
  modified : String
  untracked : String
  deleted : String
}

///|
pub fn GitStatusModule::default() -> GitStatusModule {
  {
    disabled: false,
    async_render: false,
    format: "([\\[$all_status$ahead_behind\\]]($style) )",
    style: "red bold",
    staged: "+",
    modified: "!",
    untracked: "?",
    deleted: "✘",
  }
}

///|
pub fn GitStatusModule::from_table(
  table : @config.ModuleTable,
) -> GitStatusModule {
  let d = GitStatusModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    staged: table.get_string("staged").unwrap_or(d.staged),
    modified: table.get_string("modified").unwrap_or(d.modified),
    untracked: table.get_string("untracked").unwrap_or(d.untracked),
    deleted: table.get_string("deleted").unwrap_or(d.deleted),
  }
}

///|
pub fn GitStatusModule::from_config(config : @config.Config) -> GitStatusModule {
  match config.get_raw_module("git_status") {
    Some(table) => GitStatusModule::from_table(table)
    None => GitStatusModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitStatusModule with name(_self) -> String {
  "git_status"
}

///|
pub impl @ms.PromptModule for GitStatusModule with is_async(self) -> Bool {
  self.async_render
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

  let (staged, modified, untracked, deleted) = repo.get_status()
  self.render_status(staged, modified, untracked, deleted)
}

///|
fn GitStatusModule::render_status(
  self : GitStatusModule,
  staged : Int,
  modified : Int,
  untracked : Int,
  deleted : Int,
) -> @ms.ModuleResult {
  let all_status = build_status_string([
    (staged, self.staged),
    (modified, self.modified),
    (untracked, self.untracked),
    (deleted, self.deleted),
  ])
  guard not(all_status.is_empty()) else { return Skipped("no changes") }

  let vars : Map[String, String] = {
    "all_status": all_status,
    "staged": format_count(staged, self.staged),
    "modified": format_count(modified, self.modified),
    "untracked": format_count(untracked, self.untracked),
    "deleted": format_count(deleted, self.deleted),
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

///|
pub fn GitStatusModule::schema() -> @config.ModuleSchema {
  let d = GitStatusModule::default()
  {
    name: "git_status",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "staged", field_type: @config.FString, default_value: d.staged },
      {
        name: "modified",
        field_type: @config.FString,
        default_value: d.modified,
      },
      {
        name: "untracked",
        field_type: @config.FString,
        default_value: d.untracked,
      },
      { name: "deleted", field_type: @config.FString, default_value: d.deleted },
    ],
  }
}
