///|
pub struct GitCommitModule {
  disabled : Bool
  format : String
  style : String
  only_detached : Bool
}

///|
pub fn GitCommitModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "git_commit",
  ),
) -> GitCommitModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    only_detached: config.get_prop("only_detached", default="true") == "true",
  }
}

///|
pub fn GitCommitModule::from_config(config : @config.Config) -> GitCommitModule {
  GitCommitModule::new(config=config.get_module("git_commit"))
}

///|
pub impl @ms.PromptModule for GitCommitModule with name(_self) -> String {
  "git_commit"
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
