///|
pub struct GitBranchModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  truncation_length : Int
  truncation_symbol : String
  symbol : String
  only_attached : Bool
  always_show_remote : Bool
  ignore_bare_repo : Bool
  ignore_branches : Array[String]
}

///|
pub fn GitBranchModule::default() -> GitBranchModule {
  {
    disabled: false,
    async_render: false,
    format: "on [$symbol$branch(:$remote_branch)]($style) ",
    style: "bold purple",
    truncation_length: 20,
    truncation_symbol: "…",
    symbol: " ",
    only_attached: false,
    always_show_remote: false,
    ignore_bare_repo: false,
    ignore_branches: [],
  }
}

///|
pub fn GitBranchModule::from_table(
  table : @config.ModuleTable,
) -> GitBranchModule {
  let d = GitBranchModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
    truncation_symbol: table
    .get_string("truncation_symbol")
    .unwrap_or(d.truncation_symbol),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    only_attached: table.get_bool("only_attached").unwrap_or(d.only_attached),
    always_show_remote: table
    .get_bool("always_show_remote")
    .unwrap_or(d.always_show_remote),
    ignore_bare_repo: table
    .get_bool("ignore_bare_repo")
    .unwrap_or(d.ignore_bare_repo),
    ignore_branches: match table.get_string_array("ignore_branches") {
      Some(arr) => arr
      None =>
        match table.get_string("ignore_branches") {
          Some(s) => parse_string_list(s)
          None => d.ignore_branches
        }
    },
  }
}

///|
pub fn GitBranchModule::from_config(config : @config.Config) -> GitBranchModule {
  match config.get_raw_module("git_branch") {
    Some(table) => GitBranchModule::from_table(table)
    None => GitBranchModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitBranchModule with name(_self) -> String {
  "git_branch"
}

///|
pub impl @ms.PromptModule for GitBranchModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GitBranchModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }
  guard not(self.ignore_bare_repo && repo.is_bare()) else {
    return Skipped("bare repository")
  }

  let (raw_branch, is_detached, commit_hash) = repo.get_branch()
  let (remote_name, remote_branch) = repo.get_remote_branch(raw_branch)
  self.render_branch(raw_branch, is_detached, commit_hash, remote_name, remote_branch)
}

///|
fn GitBranchModule::render_branch(
  self : GitBranchModule,
  raw_branch : String,
  is_detached : Bool,
  commit_hash : String,
  remote_name : String,
  remote_branch : String,
) -> @ms.ModuleResult {
  let branch = if is_detached {
    guard not(self.only_attached) else { return Skipped("detached HEAD") }
    guard not(commit_hash.is_empty()) else {
      return Skipped("detached HEAD with no commit")
    }
    "(\{commit_hash})"
  } else {
    raw_branch
  }

  guard not(self.ignore_branches.contains(branch)) else {
    return Skipped("branch in ignore list")
  }

  let display_branch = if branch.length() > self.truncation_length {
    branch[:self.truncation_length].to_string() + self.truncation_symbol
  } else {
    branch
  }

  let show_remote = self.always_show_remote ||
    (not(remote_branch.is_empty()) && remote_branch != branch)

  let vars : Map[String, String] = {
    "branch": display_branch,
    "remote_name": if show_remote { remote_name } else { "" },
    "remote_branch": if show_remote { remote_branch } else { "" },
    "symbol": self.symbol,
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
fn parse_string_list(s : String) -> Array[String] {
  if s.is_empty() {
    return []
  }

  s
  .split(",")
  .map(fn(sv) { sv.to_string() })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
}

///|
pub fn GitBranchModule::schema() -> @config.ModuleSchema {
  let d = GitBranchModule::default()
  {
    name: "git_branch",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "truncation_length",
        field_type: @config.FInt,
        default_value: d.truncation_length.to_string(),
      },
      {
        name: "truncation_symbol",
        field_type: @config.FString,
        default_value: d.truncation_symbol,
      },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "only_attached",
        field_type: @config.FBool,
        default_value: d.only_attached.to_string(),
      },
      {
        name: "always_show_remote",
        field_type: @config.FBool,
        default_value: d.always_show_remote.to_string(),
      },
      {
        name: "ignore_bare_repo",
        field_type: @config.FBool,
        default_value: d.ignore_bare_repo.to_string(),
      },
      {
        name: "ignore_branches",
        field_type: @config.FStringArray,
        default_value: d.ignore_branches.join(", "),
      },
    ],
  }
}
