///|
async fn main {
  let args = get_argv()
  let cmd = parse_args(args)

  match cmd {
    Prompt(pa) => run_prompt(pa)
    Timings(pa) => run_timings(pa)
    Explain(pa) => run_explain(pa)
    Module(name, pa) => run_module(name, pa)
    ModuleList => run_module_list()
    Init(shell_name, print_full) => run_init(shell_name, print_full)
    CacheClear => {
      @cache.clear_cache()
      println("Cache cleared.")
    }
    Config(name, value) => run_config(name, value)
    Toggle(name, key) => run_toggle(name, key)
    BugReport => run_bug_report()
    Completions(shell) => run_completions(shell)
    Session => run_session()
    Time => println(@async.now().to_string())
    PrintConfig(is_default) =>
      if is_default {
        println(default_config_toml())
      } else {
        let config = load_config()
        emit_warnings(config.warnings)
        println(config.to_toml())
      }
    Schema => run_schema()
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
