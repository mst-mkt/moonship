///|
pub struct Context {
  cwd : String
  home_dir : String
  status : Int
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
  config : @config.Config
  git_info : @git.GitInfo?
}

///|
pub fn Context::new(
  cwd~ : String,
  home_dir? : String = "",
  status? : Int = 0,
  cmd_duration? : Int = 0,
  jobs? : Int = 0,
  terminal_width? : Int = 80,
  config? : @config.Config = @config.Config::default(),
  git_info? : @git.GitInfo? = None,
) -> Context {
  {
    cwd,
    home_dir,
    status,
    cmd_duration,
    jobs,
    terminal_width,
    config,
    git_info,
  }
}
