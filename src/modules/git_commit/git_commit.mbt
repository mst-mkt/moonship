///|
pub struct GitCommitModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  only_detached : Bool
}

///|
pub fn GitCommitModule::default() -> GitCommitModule {
  {
    disabled: false,
    async_render: false,
    format: "[\\($hash$tag\\)]($style) ",
    style: "green bold",
    only_detached: true,
  }
}

///|
pub fn GitCommitModule::from_toml_table(
  table : @config.ModuleTable,
) -> GitCommitModule {
  let d = GitCommitModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    only_detached: @config.get_toml_bool(table, "only_detached").unwrap_or(
      d.only_detached,
    ),
  }
}

///|
pub fn GitCommitModule::from_config(config : @config.Config) -> GitCommitModule {
  match config.get_raw_module("git_commit") {
    Some(table) => GitCommitModule::from_toml_table(table)
    None => GitCommitModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitCommitModule with name(_self) -> String {
  "git_commit"
}

///|
pub impl @ms.PromptModule for GitCommitModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GitCommitModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let (_, is_detached, commit_hash) = repo.get_branch()

  guard not(self.only_detached) || is_detached else {
    return Skipped("not detached")
  }
  guard not(commit_hash.is_empty()) else { return Skipped("no commit") }

  let vars : Map[String, String] = { "hash": commit_hash, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
pub fn GitCommitModule::schema() -> @config.ModuleSchema {
  let d = GitCommitModule::default()
  {
    name: "git_commit",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "only_detached",
        field_type: @config.FBool,
        default_value: d.only_detached.to_string(),
      },
    ],
  }
}
