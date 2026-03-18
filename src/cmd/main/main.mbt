///|
fn main {
  let args = get_argv()
  let cmd = parse_args(args)

  match cmd {
    Prompt(pa) => run_prompt(pa)
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
  }
}

///|
fn run_prompt(pa : PromptArgs) -> Unit {
  let config = load_config()
  let cwd = @env.current_dir().unwrap_or(".")
  let home = @sys.get_env_var("HOME").unwrap_or("")

  let ctx = @context.Context::new(
    cwd~,
    home_dir=home,
    status=pa.status,
    cmd_duration=pa.cmd_duration,
    jobs=pa.jobs,
    terminal_width=pa.terminal_width,
    config~,
  )

  let output = render_prompt(ctx)
  println(output)
}

///|
fn build_modules() -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}
  modules["character"] = @mod_character.CharacterModule::new()
  modules["directory"] = @mod_directory.DirectoryModule::new()
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
  println(help)
}

///|
fn get_argv() -> Array[String] {
  let args = @sys.get_cli_args()

  if args.length() > 1 {
    args[1:].to_array()
  } else {
    []
  }
}
