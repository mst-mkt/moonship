///|
pub struct HgBranchModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  truncation_length : Int
  truncation_symbol : String
}

///|
pub fn HgBranchModule::default() -> HgBranchModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$branch(:$topic)]($style) ",
    style: "bold purple",
    symbol: " ",
    truncation_length: 2147483647,
    truncation_symbol: "…",
  }
}

///|
pub fn HgBranchModule::from_table(
  table : @config.ModuleTable,
) -> HgBranchModule {
  let d = HgBranchModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
    truncation_symbol: table
    .get_string("truncation_symbol")
    .unwrap_or(d.truncation_symbol),
  }
}

///|
pub fn HgBranchModule::from_config(config : @config.Config) -> HgBranchModule {
  match config.get_raw_module("hg_branch") {
    Some(table) => HgBranchModule::from_table(table)
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

  let display = if branch.length() > self.truncation_length {
    branch[:self.truncation_length].to_string() + self.truncation_symbol
  } else {
    branch
  }

  let vars : Map[String, String] = {
    "branch": display,
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
    ],
  }
}
