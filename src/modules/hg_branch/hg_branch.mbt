///|
pub struct HgBranchModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn HgBranchModule::default() -> HgBranchModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$branch(:$topic)]($style) ",
    style: "bold purple",
    symbol: " ",
  }
}

///|
pub fn HgBranchModule::from_toml_table(
  table : @config.ModuleTable,
) -> HgBranchModule {
  let d = HgBranchModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn HgBranchModule::from_config(config : @config.Config) -> HgBranchModule {
  match config.get_raw_module("hg_branch") {
    Some(table) => HgBranchModule::from_toml_table(table)
    None => HgBranchModule::default()
  }
}

///|
pub impl @ms.PromptModule for HgBranchModule with name(_self) -> String {
  "hg_branch"
}

///|
pub impl @ms.PromptModule for HgBranchModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for HgBranchModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @fs.path_exists(ctx.cwd + "/.hg") else {
    return Skipped("not in hg repo")
  }

  let hg_dir = ctx.cwd + "/.hg"

  let bookmark = read_hg_file(hg_dir + "/bookmarks.current")
  let branch = if not(bookmark.is_empty()) {
    bookmark
  } else {
    let br = read_hg_file(hg_dir + "/branch")
    if not(br.is_empty()) {
      br
    } else {
      "default"
    }
  }

  let topic = read_hg_file(hg_dir + "/topic")

  let vars : Map[String, String] = {
    "branch": branch,
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(topic.is_empty()) {
    vars["topic"] = topic
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn read_hg_file(path : String) -> String {
  let content = @fs.read_file_to_string(path) catch { _ => return "" }
  let lines = content.split("\n").collect()
  if lines.length() > 0 {
    lines[0].to_string()
  } else {
    ""
  }
}

///|
pub fn HgBranchModule::schema() -> @config.ModuleSchema {
  let d = HgBranchModule::default()
  {
    name: "hg_branch",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
