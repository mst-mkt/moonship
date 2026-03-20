///|
pub struct Context {
  cwd : String
  home_dir : String
  status : Int
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
  keymap : String
  shlvl : Int
  config : @config.Config
  mut git_repo : @git.RepoHandle?
  mut git_resolved : Bool
}

///|
pub fn Context::new(
  cwd~ : String,
  home_dir? : String = "",
  status? : Int = 0,
  cmd_duration? : Int = 0,
  jobs? : Int = 0,
  terminal_width? : Int = 80,
  keymap? : String = "",
  shlvl? : Int = 0,
  config? : @config.Config = @config.Config::default(),
) -> Context {
  {
    cwd,
    home_dir,
    status,
    cmd_duration,
    jobs,
    terminal_width,
    keymap,
    shlvl,
    config,
    git_repo: None,
    git_resolved: false,
  }
}

///|
pub fn Context::get_repo(self : Context) -> @git.RepoHandle? {
  if self.git_resolved {
    return self.git_repo
  }

  self.git_resolved = true
  self.git_repo = @git.open_repo(self.cwd)
  self.git_repo
}

///|
pub fn Context::close_repo(self : Context) -> Unit {
  if self.git_repo is Some(repo) {
    repo.close()
    self.git_repo = None
    self.git_resolved = false
  }
}
