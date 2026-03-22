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
    ignore_branches: [],
  }
}

///|
pub fn GitBranchModule::from_toml_table(
  table : @config.ModuleTable,
) -> GitBranchModule {
  let d = GitBranchModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    truncation_length: @config.get_toml_int(table, "truncation_length").unwrap_or(
      d.truncation_length,
    ),
    truncation_symbol: @config.get_toml_string(table, "truncation_symbol").unwrap_or(
      d.truncation_symbol,
    ),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    only_attached: @config.get_toml_bool(table, "only_attached").unwrap_or(
      d.only_attached,
    ),
    ignore_branches: match @config.get_toml_string(table, "ignore_branches") {
      Some(s) => parse_string_list(s)
      None => d.ignore_branches
    },
  }
}

///|
pub fn GitBranchModule::from_config(config : @config.Config) -> GitBranchModule {
  match config.get_raw_module("git_branch") {
    Some(table) => GitBranchModule::from_toml_table(table)
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

  let (raw_branch, is_detached, commit_hash) = repo.get_branch()
  self.render_branch(raw_branch, is_detached, commit_hash)
}

///|
fn GitBranchModule::render_branch(
  self : GitBranchModule,
  raw_branch : String,
  is_detached : Bool,
  commit_hash : String,
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

  let vars : Map[String, String] = {
    "branch": display_branch,
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
        name: "ignore_branches",
        field_type: @config.FStringArray,
        default_value: d.ignore_branches.join(", "),
      },
    ],
  }
}
