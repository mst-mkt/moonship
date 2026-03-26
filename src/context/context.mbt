///|
struct LazyRepo {
  cwd : String
  mut repo : @git.RepoHandle?
  mut resolved : Bool
}

///|
fn LazyRepo::new(cwd : String) -> LazyRepo {
  { cwd, repo: None, resolved: false }
}

///|
fn LazyRepo::get(self : LazyRepo) -> @git.RepoHandle? {
  if self.resolved {
    return self.repo
  }

  self.resolved = true
  self.repo = @git.open_repo(self.cwd)
  self.repo
}

///|
fn LazyRepo::close(self : LazyRepo) -> Unit {
  if self.repo is Some(repo) {
    repo.close()
    self.repo = None
    self.resolved = false
  }
}

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
  lazy_repo : LazyRepo
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
    logical_dir: if logical_dir.is_empty() {
      cwd
    } else {
      logical_dir
    },
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
    lazy_repo: LazyRepo::new(cwd),
  }
}

///|
pub fn Context::get_repo(self : Context) -> @git.RepoHandle? {
  self.lazy_repo.get()
}

///|
pub fn Context::close_repo(self : Context) -> Unit {
  self.lazy_repo.close()
}
