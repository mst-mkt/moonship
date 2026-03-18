///|
fn main {
  let args = get_argv()
  let cmd = parse_args(args)

  match cmd {
    Prompt(_pa) => println("❯")
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
fn load_config() -> @config.Config {
  let home = @sys.get_env_var("HOME").unwrap_or("")
  if home.length() == 0 {
    return @config.Config::default()
  }

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
