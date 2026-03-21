///|
pub struct HgBranchModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn HgBranchModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "hg_branch",
  ),
) -> HgBranchModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
  }
}

///|
pub fn HgBranchModule::from_config(config : @config.Config) -> HgBranchModule {
  HgBranchModule::new(config=config.get_module("hg_branch"))
}

///|
pub impl @ms.PromptModule for HgBranchModule with name(_self) -> String {
  "hg_branch"
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
