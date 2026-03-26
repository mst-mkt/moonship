///|
pub struct GitCommitModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  only_detached : Bool
  commit_hash_length : Int
  tag_symbol : String
  tag_disabled : Bool
  tag_max_candidates : Int
}

///|
pub fn GitCommitModule::default() -> GitCommitModule {
  {
    disabled: false,
    async_render: false,
    format: "[\\($hash$tag\\)]($style) ",
    style: "green bold",
    only_detached: true,
    commit_hash_length: 7,
    tag_symbol: " 🏷  ",
    tag_disabled: true,
    tag_max_candidates: 0,
  }
}

///|
pub fn GitCommitModule::from_table(
  table : @config.ModuleTable,
) -> GitCommitModule {
  let d = GitCommitModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    only_detached: table.get_bool("only_detached").unwrap_or(d.only_detached),
    commit_hash_length: table
    .get_int("commit_hash_length")
    .unwrap_or(d.commit_hash_length),
    tag_symbol: table.get_string("tag_symbol").unwrap_or(d.tag_symbol),
    tag_disabled: table.get_bool("tag_disabled").unwrap_or(d.tag_disabled),
    tag_max_candidates: table
    .get_int("tag_max_candidates")
    .unwrap_or(d.tag_max_candidates),
  }
}

///|
pub fn GitCommitModule::from_config(config : @config.Config) -> GitCommitModule {
  match config.get_raw_module("git_commit") {
    Some(table) => GitCommitModule::from_table(table)
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

  let (_, is_detached, full_hash) = repo.get_branch()

  guard not(self.only_detached) || is_detached else {
    return Skipped("not detached")
  }
  guard not(full_hash.is_empty()) else { return Skipped("no commit") }

  let hash = if full_hash.length() > self.commit_hash_length {
    full_hash[:self.commit_hash_length].to_string()
  } else {
    full_hash
  }

  let tag = if not(self.tag_disabled) {
    let tag_name = if self.tag_max_candidates > 0 {
      @exec.exec_cmd(
        "git",
        [
          "-C", ctx.cwd, "describe", "--tags",
          "--candidates=\{self.tag_max_candidates}", "HEAD",
        ],
      )
    } else {
      @exec.exec_cmd(
        "git",
        ["-C", ctx.cwd, "describe", "--tags", "--exact-match", "HEAD"],
      )
    }

    if tag_name.is_empty() { "" } else { self.tag_symbol + tag_name }
  } else {
    ""
  }

  let vars : Map[String, String] = {
    "hash": hash,
    "tag": tag,
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
      {
        name: "commit_hash_length",
        field_type: @config.FInt,
        default_value: d.commit_hash_length.to_string(),
      },
      {
        name: "tag_symbol",
        field_type: @config.FString,
        default_value: d.tag_symbol,
      },
      {
        name: "tag_disabled",
        field_type: @config.FBool,
        default_value: d.tag_disabled.to_string(),
      },
    ],
  }
}
