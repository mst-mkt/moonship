///|
pub struct GitMetricsModule {
  disabled : Bool
  format : String
  added_style : String
  deleted_style : String
  only_nonzero_diffs : Bool
}

///|
pub fn GitMetricsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "git_metrics",
  ),
) -> GitMetricsModule {
  {
    disabled: config.disabled,
    format: config.format,
    added_style: config.get_prop("added_style", default="bold green"),
    deleted_style: config.get_prop("deleted_style", default="bold red"),
    only_nonzero_diffs: config.get_prop("only_nonzero_diffs", default="true") !=
    "false",
  }
}

///|
pub fn GitMetricsModule::from_config(
  config : @config.Config,
) -> GitMetricsModule {
  GitMetricsModule::new(config=config.get_module("git_metrics"))
}

///|
pub impl @ms.PromptModule for GitMetricsModule with name(_self) -> String {
  "git_metrics"
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
