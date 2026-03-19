///|
async fn main {
  let args = get_argv()
  let cmd = parse_args(args)

  match cmd {
    Prompt(pa) => run_prompt(pa)
    Init(shell_name) => run_init(shell_name)
    Time => println(@async.now().to_string())
    PrintConfig => {
      let config = load_config()
      println(config.to_toml())
    }
    Version => println("moonship 0.0.0")
    Help => run_help()
    UnknownCommand(name) => {
      println("moonship: unknown command '\{name}'")
      run_help()
    }
    UnknownShell => {
      println("moonship: 'init' requires a shell name")
      println("Supported shells: zsh, bash, fish")
    }
  }
}

///|
async fn run_prompt(pa : PromptArgs) -> Unit {
  let config = load_config()
  let cwd = @env.current_dir().unwrap_or(".")
  let home_dir = @sys.get_env_var("HOME").unwrap_or("")

  let git_info = if @git.initialize() {
    let info = @git.get_info(cwd)
    @git.finalize()
    info
  } else {
    None
  }

  let ctx = @context.Context::new(
    cwd~,
    home_dir~,
    status=pa.status,
    cmd_duration=pa.cmd_duration,
    jobs=pa.jobs,
    terminal_width=pa.terminal_width,
    config~,
    git_info~,
  )

  let output = render_prompt(ctx)
  println(output)
}

///|
fn build_modules() -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}
  modules["character"] = @mod_character.CharacterModule::new()
  modules["directory"] = @mod_directory.DirectoryModule::new()
  modules["git_branch"] = @mod_git_branch.GitBranchModule::new()
  modules["git_status"] = @mod_git_status.GitStatusModule::new()
  modules
}

///|
fn render_prompt(ctx : @context.Context) -> String {
  let modules = build_modules()

  @ms.extract_module_names(ctx.config.format)
  .iter()
  .filter_map(fn(name) { modules.get(name) })
  .filter_map(fn(m) { m.execute(ctx) })
  .map(fn(o) { o.render() })
  .collect()
  .join("")
}

///|
async fn run_init(shell_name : String) -> Unit {
  match @shell.Shell::from_string(shell_name) {
    Some(shell) => {
      let bin = self_exe()
      println(@shell.generate_init(shell, bin))
    }
    None =>
      println(
        "moonship: unknown shell '\{shell_name}'. Supported: zsh, bash, fish",
      )
  }
}

///|
async fn self_exe() -> String {
  if @fs.path_exists("/proc/self/exe") {
    let devnull = @process.redirect_to_file("/dev/null")
    let (code, data) = @process.collect_stdout(
      "readlink",
      ["-f", "/proc/self/exe"][:],
      stderr=devnull,
    ) catch {
      _ => return fallback_exe()
    }

    if code == 0 {
      let path = (data.text() catch { _ => return fallback_exe() })
        .trim(chars=" \n\r\t")
        .to_string()
      if not(path.is_empty()) {
        return path
      }
    }
  }

  fallback_exe()
}

///|
fn fallback_exe() -> String {
  let args = @sys.get_cli_args()
  guard args.length() > 0 else { return "moonship" }

  let arg0 = args[0]

  if arg0.has_prefix("/") {
    return arg0
  }
  if arg0.contains("/") {
    return @env.current_dir().unwrap_or(".") + "/" + arg0
  }

  let path_var = @sys.get_env_var("PATH").unwrap_or("")
  path_var
  .split(":")
  .map(fn(dir) { dir.to_string() })
  .filter(fn(dir) { not(dir.is_empty()) })
  .map(fn(dir) { dir + "/" + arg0 })
  .find_first(fn(candidate) { @fs.path_exists(candidate) })
  .unwrap_or(arg0)
}

///|
fn load_config() -> @config.Config {
  let home = @sys.get_env_var("HOME").unwrap_or("")
  guard not(home.is_empty()) else { return @config.Config::default() }

  let path = "\{home}/.config/moonship/moonship.toml"
  let content = @fs.read_file_to_string(path) catch {
    _ => return @config.Config::default()
  }

  @config.Config::from_toml(content) catch {
    _ => @config.Config::default()
  }
}

///|
fn run_help() -> Unit {
  let help =
    #|moonship - A fast async shell prompt
    #|
    #|Usage:
    #|  moonship prompt [options]    Generate prompt string
    #|  moonship init <shell>        Print shell init script
    #|  moonship time                Print current time in ms
    #|  moonship print-config        Print active configuration
    #|  moonship version             Print version
    #|  moonship help                Print this help
    #|
    #|Prompt options:
    #|  --status=<n>              Exit code of last command
    #|  --cmd-duration=<ms>       Duration of last command
    #|  --jobs=<n>                Number of background jobs
    #|  --terminal-width=<cols>   Terminal width in columns
    #|
    #|Supported shells: zsh, bash, fish
    #|
  println(help)
}

///|
fn get_argv() -> Array[String] {
  let args = @sys.get_cli_args()
  guard args.length() > 1 else { return [] }

  args[1:].to_array()
}
