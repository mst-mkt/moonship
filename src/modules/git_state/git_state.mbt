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
pub fn GitStateModule::from_toml_table(
  table : @config.ModuleTable,
) -> GitStateModule {
  let d = GitStateModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    rebase: @config.get_toml_string(table, "rebase").unwrap_or(d.rebase),
    merge: @config.get_toml_string(table, "merge").unwrap_or(d.merge),
    revert: @config.get_toml_string(table, "revert").unwrap_or(d.revert),
    cherry_pick: @config.get_toml_string(table, "cherry_pick").unwrap_or(
      d.cherry_pick,
    ),
    bisect: @config.get_toml_string(table, "bisect").unwrap_or(d.bisect),
  }
}

///|
pub fn GitStateModule::from_config(config : @config.Config) -> GitStateModule {
  match config.get_raw_module("git_state") {
    Some(table) => GitStateModule::from_toml_table(table)
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

  let git_dir = repo.repo_root() + "/.git"
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
  if @fs.path_exists(git_dir + "/rebase-merge") ||
    @fs.path_exists(git_dir + "/rebase-apply") {
    return config.rebase
  }
  if @fs.path_exists(git_dir + "/MERGE_HEAD") {
    return config.merge
  }
  if @fs.path_exists(git_dir + "/CHERRY_PICK_HEAD") {
    return config.cherry_pick
  }
  if @fs.path_exists(git_dir + "/REVERT_HEAD") {
    return config.revert
  }
  if @fs.path_exists(git_dir + "/BISECT_LOG") {
    return config.bisect
  }

  ""
}
