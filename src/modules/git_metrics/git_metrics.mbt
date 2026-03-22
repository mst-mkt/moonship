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
pub fn GitMetricsModule::from_table(
  table : @config.ModuleTable,
) -> GitMetricsModule {
  let d = GitMetricsModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    added_style: table.get_string("added_style").unwrap_or(d.added_style),
    deleted_style: table.get_string("deleted_style").unwrap_or(d.deleted_style),
    only_nonzero_diffs: table
    .get_bool("only_nonzero_diffs")
    .unwrap_or(d.only_nonzero_diffs),
  }
}

///|
pub fn GitMetricsModule::from_config(
  config : @config.Config,
) -> GitMetricsModule {
  match config.get_raw_module("git_metrics") {
    Some(table) => GitMetricsModule::from_table(table)
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

///|
pub fn GitMetricsModule::schema() -> @config.ModuleSchema {
  let d = GitMetricsModule::default()
  {
    name: "git_metrics",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      {
        name: "added_style",
        field_type: @config.FString,
        default_value: d.added_style,
      },
      {
        name: "deleted_style",
        field_type: @config.FString,
        default_value: d.deleted_style,
      },
      {
        name: "only_nonzero_diffs",
        field_type: @config.FBool,
        default_value: d.only_nonzero_diffs.to_string(),
      },
    ],
  }
}
