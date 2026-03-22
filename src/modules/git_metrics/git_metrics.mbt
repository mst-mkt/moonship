///|
pub struct GitMetricsModule {
  disabled : Bool
  async_render : Bool
  format : String
  added_style : String
  deleted_style : String
  only_nonzero_diffs : Bool
}

///|
pub fn GitMetricsModule::default() -> GitMetricsModule {
  {
    disabled: true,
    async_render: false,
    format: "([+$added]($added_style) )([-$deleted]($deleted_style) )",
    added_style: "bold green",
    deleted_style: "bold red",
    only_nonzero_diffs: true,
  }
}

///|
pub fn GitMetricsModule::from_toml_table(
  table : @config.ModuleTable,
) -> GitMetricsModule {
  let d = GitMetricsModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    added_style: @config.get_toml_string(table, "added_style").unwrap_or(
      d.added_style,
    ),
    deleted_style: @config.get_toml_string(table, "deleted_style").unwrap_or(
      d.deleted_style,
    ),
    only_nonzero_diffs: @config.get_toml_bool(table, "only_nonzero_diffs").unwrap_or(
      d.only_nonzero_diffs,
    ),
  }
}

///|
pub fn GitMetricsModule::from_config(
  config : @config.Config,
) -> GitMetricsModule {
  match config.get_raw_module("git_metrics") {
    Some(table) => GitMetricsModule::from_toml_table(table)
    None => GitMetricsModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitMetricsModule with name(_self) -> String {
  "git_metrics"
}

///|
pub impl @ms.PromptModule for GitMetricsModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GitMetricsModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(_) else { return Skipped("not in a git repo") }

  let output = @exec.exec_cmd("git", ["-C", ctx.cwd, "diff", "--shortstat"])

  let (added, deleted) = parse_shortstat(output)

  if self.only_nonzero_diffs && added == 0 && deleted == 0 {
    return Skipped("no changes")
  }

  let vars : Map[String, String] = {
    "added_style": self.added_style,
    "deleted_style": self.deleted_style,
  }

  if not(self.only_nonzero_diffs) || added > 0 {
    vars["added"] = added.to_string()
  }

  if not(self.only_nonzero_diffs) || deleted > 0 {
    vars["deleted"] = deleted.to_string()
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_shortstat(output : String) -> (Int, Int) {
  let mut added = 0
  let mut deleted = 0
  let parts = output.split(",").collect()

  for part in parts {
    let s = part.to_string()

    if s.contains("insertion") {
      added = extract_leading_number(s)
    } else if s.contains("deletion") {
      deleted = extract_leading_number(s)
    }
  }

  (added, deleted)
}

///|
fn extract_leading_number(s : String) -> Int {
  let mut result = 0
  let mut found = false

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
      found = true
    } else if found {
      break
    }
  }

  result
}
