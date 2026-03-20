///|
pub struct GitStateModule {
  disabled : Bool
  format : String
  style : String
  rebase : String
  merge : String
  revert : String
  cherry_pick : String
  bisect : String
}

///|
pub fn GitStateModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "git_state",
  ),
) -> GitStateModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    rebase: config.get_prop("rebase", default="REBASING"),
    merge: config.get_prop("merge", default="MERGING"),
    revert: config.get_prop("revert", default="REVERTING"),
    cherry_pick: config.get_prop("cherry_pick", default="CHERRY-PICKING"),
    bisect: config.get_prop("bisect", default="BISECTING"),
  }
}

///|
pub fn GitStateModule::from_config(config : @config.Config) -> GitStateModule {
  GitStateModule::new(config=config.get_module("git_state"))
}

///|
pub impl @ms.PromptModule for GitStateModule with name(_self) -> String {
  "git_state"
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

  let style = @terminal.parse_style(self.style)
  let vars : Map[String, String] = { "state": state, "style": self.style }
  let segments = @ms.format_string(self.format, vars, style)

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
