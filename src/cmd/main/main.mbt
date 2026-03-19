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

///|
fn build_context(pa : PromptArgs) -> @context.Context {
  let config = load_config()
  let cwd = @env.current_dir().unwrap_or(".")
  let home_dir = @sys.get_env_var("HOME").unwrap_or("")

  @context.Context::new(
    cwd~,
    home_dir~,
    status=pa.status,
    cmd_duration=pa.cmd_duration,
    jobs=pa.jobs,
    terminal_width=pa.terminal_width,
    config~,
  )
}

///|
fn run_prompt(pa : PromptArgs) -> Unit {
  let shell = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  let use_cache = shell == "zsh" || shell == "fish"
  let ctx = build_context(pa)

  // Cache hit: return immediately (sync path only)
  if use_cache && not(pa.is_async) {
    if @cache.read_prompt(ctx.cwd, pa.status, ctx.config.cache_ttl) is Some(
      cached,
    ) {
      println(wrap_for_shell(shell, cached))
      return
    }
  }

  // Compute prompt
  let raw = render_prompt(ctx)
  ctx.close_repo()
  println(wrap_for_shell(shell, raw))

  // Write cache (store raw, without shell-specific wrapping)
  if use_cache {
    @cache.write_prompt(ctx.cwd, pa.status, raw)
  }

  // Notify fish shell
  if pa.is_async && shell == "fish" {
    notify_parent() |> ignore
  }
}

///|
extern "C" fn notify_parent() -> Int = "moonship_notify_parent"

///|
fn run_timings(pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  let modules = build_modules(ctx.config)
  let module_names = @ms.extract_module_names(ctx.config.format)

  let entries : Array[(String, Int64, String)] = []

  for name in module_names {
    guard modules.get(name) is Some(m) else { continue }

    let start = @async.now()
    let result = m.execute(ctx)
    let elapsed = @async.now() - start

    let output = match result {
      Output(out) => out.render().replace(old="\n", new="\\n")
      Skipped(_) | Disabled => ""
    }

    if elapsed > 0L || not(output.is_empty()) {
      entries.push((name, elapsed, output))
    }
  }

  ctx.close_repo()

  entries.sort_by(fn(a, b) { b.1.compare(a.1) })

  let max_name = max_length(entries.iter().map(fn(e) { e.0 }))
  let max_dur = max_length(entries.iter().map(fn(e) { format_duration(e.1) }))

  println("")
  println(" Here are the timings of modules in your prompt (>=1ms or output):")
  for entry in entries {
    let (name, ms, output) = entry
    let dur = format_duration(ms)

    println(
      " \{pad_right(name, max_name)}  -  \{pad_left(dur, max_dur)}  -   \"\{output}\"",
    )
  }
}

///|
fn max_length(iter : Iter[String]) -> Int {
  iter.fold(init=0, fn(max, s) {
    let len = s.length()
    if len > max {
      len
    } else {
      max
    }
  })
}

///|
fn format_duration(ms : Int64) -> String {
  if ms == 0L {
    "<1ms"
  } else {
    "\{ms}ms"
  }
}

///|
fn pad_right(s : String, width : Int) -> String {
  guard s.length() < width else { return s }

  let buf = StringBuilder::new()
  buf.write_string(s)
  for _ in 0..<(width - s.length()) {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
fn pad_left(s : String, width : Int) -> String {
  guard s.length() < width else { return s }

  let buf = StringBuilder::new()
  for _ in 0..<(width - s.length()) {
    buf.write_char(' ')
  }
  buf.write_string(s)
  buf.to_string()
}

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}
  modules["character"] = @mod_character.CharacterModule::from_config(config)
  modules["directory"] = @mod_directory.DirectoryModule::from_config(config)
  modules["git_branch"] = @mod_git_branch.GitBranchModule::from_config(config)
  modules["git_status"] = @mod_git_status.GitStatusModule::from_config(config)
  modules
}

///|
fn wrap_for_shell(shell : String, s : String) -> String {
  if shell == "zsh" {
    wrap_ansi_for_zsh(s)
  } else {
    s
  }
}

///|
fn wrap_ansi_for_zsh(s : String) -> String {
  let buf = StringBuilder::new()
  let len = s.length()
  let mut i = 0

  while i < len {
    if i + 1 < len &&
      s[i].unsafe_to_char() == '\u001b' &&
      s[i + 1].unsafe_to_char() == '[' {
      buf.write_string("%{\u001b[")
      i += 2

      while i < len {
        let ch = s[i].unsafe_to_char()
        buf.write_char(ch)
        i += 1
        if ch == 'm' {
          break
        }
      }

      buf.write_string("%}")
    } else {
      buf.write_char(s[i].unsafe_to_char())
      i += 1
    }
  }

  buf.to_string()
}

///|
fn render_prompt(ctx : @context.Context) -> String {
  let modules = build_modules(ctx.config)
  let segment_vars : Map[String, Array[@ms.Segment]] = {}

  for name in @ms.extract_module_names(ctx.config.format) {
    guard modules.get(name) is Some(m) else { continue }
    guard m.execute(ctx) is Output(output) else { continue }
    segment_vars[name] = output.segments
  }

  @ms.compose_segments(ctx.config.format, segment_vars).render()
}

///|
fn run_init(shell_name : String) -> Unit {
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
fn self_exe() -> String {
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
  let path = @sys.get_env_var("MOONSHIP_CONFIG").unwrap_or("")
  let path = if not(path.is_empty()) {
    path
  } else {
    let home = @sys.get_env_var("HOME").unwrap_or("")
    guard not(home.is_empty()) else { return @config.Config::default() }
    "\{home}/.config/moonship/moonship.toml"
  }

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
    #|  moonship timings [options]   Show module execution times
    #|  moonship init <shell>        Print shell init script
    #|  moonship cache clear         Clear cached data
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
    #|  --async                   Recompute and update cache
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
