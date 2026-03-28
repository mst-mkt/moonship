///|
pub struct FossilMetricsModule {
  disabled : Bool
  async_render : Bool
  format : String
  added_style : String
  deleted_style : String
  only_nonzero_diffs : Bool
}

///|
pub fn FossilMetricsModule::default() -> FossilMetricsModule {
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
pub fn FossilMetricsModule::from_table(
  table : @config.ModuleTable,
) -> FossilMetricsModule {
  let d = FossilMetricsModule::default()
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
pub fn FossilMetricsModule::from_config(
  config : @config.Config,
) -> FossilMetricsModule {
  match config.get_raw_module("fossil_metrics") {
    Some(table) => FossilMetricsModule::from_table(table)
    None => FossilMetricsModule::default()
  }
}

///|
pub impl @ms.PromptModule for FossilMetricsModule with name(_self) -> String {
  "fossil_metrics"
}

///|
pub impl @ms.PromptModule for FossilMetricsModule with is_async(self) -> Bool {
  self.async_render
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
  let lines = @exec.split_to_strings(output, "\n")

  loop lines.length() - 1 {
    i => {
      guard i >= 0 else { break (0, 0) }

      let s = lines[i]
      if s.contains("TOTAL") {
        let nums = s
          .split(" ")
          .map(fn(p) { p.to_string() })
          .filter(fn(p) {
            not(p.is_empty()) &&
            p.iter().nth(0).map(fn(c) { c >= '0' && c <= '9' }).unwrap_or(false)
          })
          .map(fn(p) { parse_num(p) })
          .collect()
        if nums.length() >= 2 {
          break (nums[0], nums[1])
        }
      }
      continue i - 1
    }
  }
}

///|
fn parse_num(s : String) -> Int {
  s
  .iter()
  .fold(init=(0, true), fn(acc, c) {
    let (result, active) = acc
    if active && c >= '0' && c <= '9' {
      (result * 10 + (c.to_int() - '0'.to_int()), true)
    } else {
      (result, false)
    }
  }).0
}

///|
pub fn FossilMetricsModule::schema() -> @config.ModuleSchema {
  let d = FossilMetricsModule::default()
  {
    name: "fossil_metrics",
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
