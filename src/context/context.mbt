///|
pub struct Context {
  cwd : String
  logical_dir : String
  home_dir : String
  status : Int
  pipestatus : Array[String]
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
  keymap : String
  shlvl : Int
  config : @config.Config
  palette : Map[String, String]
  mut git_repo : @git.RepoHandle?
  mut git_resolved : Bool
}

///|
pub fn Context::new(
  cwd~ : String,
  logical_dir? : String = "",
  home_dir? : String = "",
  status? : Int = 0,
  pipestatus? : Array[String] = [],
  cmd_duration? : Int = 0,
  jobs? : Int = 0,
  terminal_width? : Int = 80,
  keymap? : String = "",
  shlvl? : Int = 0,
  config? : @config.Config = @config.Config::default(),
) -> Context {
  {
    cwd,
    logical_dir: if logical_dir.is_empty() { cwd } else { logical_dir },
    home_dir,
    status,
    pipestatus,
    cmd_duration,
    jobs,
    terminal_width,
    keymap,
    shlvl,
    config,
    palette: config.get_active_palette(),
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
