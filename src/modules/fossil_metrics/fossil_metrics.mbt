///|
pub struct FossilMetricsModule {
  disabled : Bool
  format : String
  added_style : String
  deleted_style : String
  only_nonzero_diffs : Bool
}

///|
pub fn FossilMetricsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "fossil_metrics",
  ),
) -> FossilMetricsModule {
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
pub fn FossilMetricsModule::from_config(
  config : @config.Config,
) -> FossilMetricsModule {
  FossilMetricsModule::new(config=config.get_module("fossil_metrics"))
}

///|
pub impl @ms.PromptModule for FossilMetricsModule with name(_self) -> String {
  "fossil_metrics"
}

///|
pub impl @ms.PromptModule for FossilMetricsModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for FossilMetricsModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @fs.path_exists(ctx.cwd + "/.fslckout") ||
    @fs.path_exists(ctx.cwd + "/_FOSSIL_") else {
    return Skipped("not in fossil repo")
  }

  let output = @exec.exec_cmd_full("fossil", ["diff", "-i", "--numstat"])
  let (added, deleted) = parse_fossil_numstat(output)

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
fn parse_fossil_numstat(output : String) -> (Int, Int) {
  let lines = output.split("\n").collect()

  for i = lines.length() - 1; i >= 0; i = i - 1 {
    let s = lines[i].to_string()
    if s.contains("TOTAL") {
      let parts = s.split(" ").collect()
      let nums : Array[Int] = []

      for part in parts {
        let p = part.to_string()
        if not(p.is_empty()) &&
          p[0].unsafe_to_char() >= '0' &&
          p[0].unsafe_to_char() <= '9' {
          nums.push(parse_num(p))
        }
      }

      if nums.length() >= 2 {
        return (nums[0], nums[1])
      }
    }
  }

  (0, 0)
}

///|
fn parse_num(s : String) -> Int {
  let mut result = 0

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      break
    }
  }

  result
}
