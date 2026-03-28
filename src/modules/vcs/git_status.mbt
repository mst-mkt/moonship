///|
pub struct GitStatusModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  staged : String
  modified : String
  untracked : String
  deleted : String
  conflicted : String
  renamed : String
  typechanged : String
  stashed : String
  ahead : String
  behind : String
  up_to_date : String
  diverged : String
  ignore_submodules : Bool
}

///|
pub fn GitStatusModule::default() -> GitStatusModule {
  {
    disabled: false,
    async_render: false,
    format: "([\\[$all_status$ahead_behind\\]]($style) )",
    style: "red bold",
    staged: "+",
    modified: "!",
    untracked: "?",
    deleted: "✘",
    conflicted: "=",
    renamed: "»",
    typechanged: "",
    stashed: "$",
    ahead: "⇡",
    behind: "⇣",
    up_to_date: "",
    diverged: "⇕",
    ignore_submodules: false,
  }
}

///|
pub fn GitStatusModule::from_table(
  table : @config.ModuleTable,
) -> GitStatusModule {
  let d = GitStatusModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    staged: table.get_string("staged").unwrap_or(d.staged),
    modified: table.get_string("modified").unwrap_or(d.modified),
    untracked: table.get_string("untracked").unwrap_or(d.untracked),
    deleted: table.get_string("deleted").unwrap_or(d.deleted),
    conflicted: table.get_string("conflicted").unwrap_or(d.conflicted),
    renamed: table.get_string("renamed").unwrap_or(d.renamed),
    typechanged: table.get_string("typechanged").unwrap_or(d.typechanged),
    stashed: table.get_string("stashed").unwrap_or(d.stashed),
    ahead: table.get_string("ahead").unwrap_or(d.ahead),
    behind: table.get_string("behind").unwrap_or(d.behind),
    up_to_date: table.get_string("up_to_date").unwrap_or(d.up_to_date),
    diverged: table.get_string("diverged").unwrap_or(d.diverged),
    ignore_submodules: table
    .get_bool("ignore_submodules")
    .unwrap_or(d.ignore_submodules),
  }
}

///|
pub fn GitStatusModule::from_config(config : @config.Config) -> GitStatusModule {
  match config.get_raw_module("git_status") {
    Some(table) => GitStatusModule::from_table(table)
    None => GitStatusModule::default()
  }
}

///|
pub impl @ms.PromptModule for GitStatusModule with name(_self) -> String {
  "git_status"
}

///|
pub impl @ms.PromptModule for GitStatusModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GitStatusModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.get_repo() is Some(repo) else {
    return Skipped("not in git repository")
  }

  let status = if self.ignore_submodules {
    parse_git_porcelain(
      @exec.exec_cmd_full("git", [
        "-C",
        ctx.cwd,
        "status",
        "--porcelain",
        "--ignore-submodules=dirty",
      ]),
      repo,
    )
  } else {
    repo.get_status()
  }
  let ahead_behind = @exec.exec_cmd("git", [
    "-C",
    ctx.cwd,
    "rev-list",
    "--count",
    "--left-right",
    "@{upstream}...HEAD",
  ])

  let (ahead_count, behind_count) = parse_ahead_behind(ahead_behind)
  self.render_status(status, ahead_count, behind_count)
}

///|
fn GitStatusModule::render_status(
  self : GitStatusModule,
  status : @git.GitStatus,
  ahead_count : Int,
  behind_count : Int,
) -> @ms.ModuleResult {
  let all_status = build_status_string([
    (status.staged, self.staged),
    (status.modified, self.modified),
    (status.untracked, self.untracked),
    (status.deleted, self.deleted),
    (status.conflicted, self.conflicted),
    (status.renamed, self.renamed),
    (status.typechanged, self.typechanged),
    (status.stashed, self.stashed),
  ])

  let ahead_behind = build_ahead_behind(
    ahead_count,
    behind_count,
    self.ahead,
    self.behind,
    self.up_to_date,
    self.diverged,
  )

  guard not(all_status.is_empty()) || not(ahead_behind.is_empty()) else {
    return Skipped("no changes")
  }

  let vars : Map[String, String] = {
    "all_status": all_status,
    "ahead_behind": ahead_behind,
    "staged": format_count(status.staged, self.staged),
    "modified": format_count(status.modified, self.modified),
    "untracked": format_count(status.untracked, self.untracked),
    "deleted": format_count(status.deleted, self.deleted),
    "conflicted": format_count(status.conflicted, self.conflicted),
    "renamed": format_count(status.renamed, self.renamed),
    "typechanged": format_count(status.typechanged, self.typechanged),
    "stashed": format_count(status.stashed, self.stashed),
    "ahead": if ahead_count > 0 {
      self.ahead
    } else {
      ""
    },
    "behind": if behind_count > 0 {
      self.behind
    } else {
      ""
    },
    "up_to_date": if ahead_count == 0 && behind_count == 0 {
      self.up_to_date
    } else {
      ""
    },
    "diverged": if ahead_count > 0 && behind_count > 0 {
      self.diverged
    } else {
      ""
    },
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
fn format_count(count : Int, symbol : String) -> String {
  if count <= 0 {
    return ""
  }

  symbol
  .replace(old="${count}", new=count.to_string())
  .replace(old="$count", new=count.to_string())
}

///|
fn build_status_string(counts : Array[(Int, String)]) -> String {
  counts
  .iter()
  .map(fn(pair) { format_count(pair.0, pair.1) })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
  .join("")
}

///|
fn parse_git_porcelain(
  output : String,
  repo : @git.RepoHandle,
) -> @git.GitStatus {
  let stashed = if @fs.path_exists("\{repo.repo_root()}/.git/refs/stash") ||
    ({
      let packed = "\{repo.repo_root()}/.git/packed-refs"
      @fs.path_exists(packed) &&
      (@fs.read_file_to_string(packed) catch { _ => "" }).contains("refs/stash")
    }) {
    1
  } else {
    0
  }

  output
  .split("\n")
  .fold(
    init={
      staged: 0,
      modified: 0,
      untracked: 0,
      deleted: 0,
      conflicted: 0,
      renamed: 0,
      typechanged: 0,
      stashed,
    },
    fn(acc : @git.GitStatus, line) {
      let s = line.to_string()
      guard s.length() >= 2 else { return acc }

      let x = s[0].unsafe_to_char()
      let y = s[1].unsafe_to_char()

      {
        staged: acc.staged +
        Bool::to_int(x == 'A' || x == 'M' || x == 'D' || x == 'R'),
        modified: acc.modified + Bool::to_int(y == 'M'),
        untracked: acc.untracked + Bool::to_int(x == '?' && y == '?'),
        deleted: acc.deleted + Bool::to_int(x == 'D' || y == 'D'),
        conflicted: acc.conflicted + Bool::to_int(x == 'U' || y == 'U'),
        renamed: acc.renamed + Bool::to_int(x == 'R'),
        typechanged: acc.typechanged + Bool::to_int(x == 'T' || y == 'T'),
        stashed: acc.stashed,
      }
    },
  )
}

///|
fn parse_ahead_behind(output : String) -> (Int, Int) {
  guard not(output.is_empty()) else { return (0, 0) }

  match @exec.split_to_strings(output, "\t") {
    [behind_str, ahead_str] => {
      let behind = @strconv.parse_int(behind_str) catch { _ => 0 }
      let ahead = @strconv.parse_int(ahead_str) catch { _ => 0 }
      (ahead, behind)
    }
    _ => (0, 0)
  }
}

///|
fn build_ahead_behind(
  ahead : Int,
  behind : Int,
  ahead_sym : String,
  behind_sym : String,
  up_to_date_sym : String,
  diverged_sym : String,
) -> String {
  if ahead > 0 && behind > 0 {
    diverged_sym
    .replace(old="${ahead_count}", new=ahead.to_string())
    .replace(old="$ahead_count", new=ahead.to_string())
    .replace(old="${behind_count}", new=behind.to_string())
    .replace(old="$behind_count", new=behind.to_string())
    .replace(old="${count}", new=(ahead + behind).to_string())
    .replace(old="$count", new=(ahead + behind).to_string())
  } else if ahead > 0 {
    ahead_sym
    .replace(old="${count}", new=ahead.to_string())
    .replace(old="$count", new=ahead.to_string())
  } else if behind > 0 {
    behind_sym
    .replace(old="${count}", new=behind.to_string())
    .replace(old="$count", new=behind.to_string())
  } else if not(up_to_date_sym.is_empty()) {
    up_to_date_sym
  } else {
    ""
  }
}

///|
pub fn GitStatusModule::schema() -> @config.ModuleSchema {
  let d = GitStatusModule::default()
  {
    name: "git_status",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "staged", field_type: @config.FString, default_value: d.staged },
      {
        name: "modified",
        field_type: @config.FString,
        default_value: d.modified,
      },
      {
        name: "untracked",
        field_type: @config.FString,
        default_value: d.untracked,
      },
      { name: "deleted", field_type: @config.FString, default_value: d.deleted },
      {
        name: "conflicted",
        field_type: @config.FString,
        default_value: d.conflicted,
      },
      { name: "renamed", field_type: @config.FString, default_value: d.renamed },
      {
        name: "typechanged",
        field_type: @config.FString,
        default_value: d.typechanged,
      },
      { name: "stashed", field_type: @config.FString, default_value: d.stashed },
      { name: "ahead", field_type: @config.FString, default_value: d.ahead },
      { name: "behind", field_type: @config.FString, default_value: d.behind },
      {
        name: "up_to_date",
        field_type: @config.FString,
        default_value: d.up_to_date,
      },
      {
        name: "diverged",
        field_type: @config.FString,
        default_value: d.diverged,
      },
      {
        name: "ignore_submodules",
        field_type: @config.FBool,
        default_value: d.ignore_submodules.to_string(),
      },
    ],
  }
}
