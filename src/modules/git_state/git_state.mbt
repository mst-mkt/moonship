///|
pub struct GitStateModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  rebase : String
  merge : String
  revert : String
  cherry_pick : String
  bisect : String
}

///|
pub fn GitStateModule::default() -> GitStateModule {
  {
    disabled: false,
    async_render: false,
    format: "\\([$state( $progress_current/$progress_total)]($style)\\) ",
    style: "bold yellow",
    rebase: "REBASING",
    merge: "MERGING",
    revert: "REVERTING",
    cherry_pick: "CHERRY-PICKING",
    bisect: "BISECTING",
  }
}

///|
pub fn GitStateModule::from_table(
  table : @config.ModuleTable,
) -> GitStateModule {
  let d = GitStateModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    rebase: table.get_string("rebase").unwrap_or(d.rebase),
    merge: table.get_string("merge").unwrap_or(d.merge),
    revert: table.get_string("revert").unwrap_or(d.revert),
    cherry_pick: table.get_string("cherry_pick").unwrap_or(d.cherry_pick),
    bisect: table.get_string("bisect").unwrap_or(d.bisect),
  }
}

///|
pub fn GitStateModule::from_config(config : @config.Config) -> GitStateModule {
  match config.get_raw_module("git_state") {
    Some(table) => GitStateModule::from_table(table)
    None => GitStateModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitStateModule with name(_self) -> String {
  "git_state"
}

///|
pub impl @ms.PromptModule for GitStateModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GitStateModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let git_dir = "\{repo.repo_root()}/.git"
  let state = detect_state(git_dir, self)
  guard not(state.is_empty()) else { return Skipped("clean state") }

  let vars : Map[String, String] = { "state": state, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn detect_state(git_dir : String, config : GitStateModule) -> String {
  if @fs.path_exists("\{git_dir}/rebase-merge") ||
    @fs.path_exists("\{git_dir}/rebase-apply") {
    return config.rebase
  }
  if @fs.path_exists("\{git_dir}/MERGE_HEAD") {
    return config.merge
  }
  if @fs.path_exists("\{git_dir}/CHERRY_PICK_HEAD") {
    return config.cherry_pick
  }
  if @fs.path_exists("\{git_dir}/REVERT_HEAD") {
    return config.revert
  }
  if @fs.path_exists("\{git_dir}/BISECT_LOG") {
    return config.bisect
  }

  ""
}

///|
pub fn GitStateModule::schema() -> @config.ModuleSchema {
  let d = GitStateModule::default()
  {
    name: "git_state",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "rebase", field_type: @config.FString, default_value: d.rebase },
      { name: "merge", field_type: @config.FString, default_value: d.merge },
      { name: "revert", field_type: @config.FString, default_value: d.revert },
      {
        name: "cherry_pick",
        field_type: @config.FString,
        default_value: d.cherry_pick,
      },
      { name: "bisect", field_type: @config.FString, default_value: d.bisect },
    ],
  }
}
