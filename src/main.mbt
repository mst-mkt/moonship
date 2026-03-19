///|
fn main {
  let args = get_argv()
  let cmd = parse_args(args)

  match cmd {
    Prompt(pa) => run_prompt(pa)
    Timings(pa) => run_timings(pa)
    Init(shell_name) => run_init(shell_name)
    CacheClear => {
      @cache.clear_cache()
      println("Cache cleared.")
    }
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
