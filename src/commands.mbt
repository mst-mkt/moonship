///|
fn run_prompt(pa : PromptArgs) -> Unit {
  let shell = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  let use_cache = (shell == "zsh" || shell == "fish") && pa.keymap.is_empty()
  let ctx = build_context(pa)

  // Cache hit: return immediately (sync path only)
  if use_cache && not(pa.is_async) {
    if @cache.read_prompt(ctx.cwd, pa.status, ctx.config.cache_ttl)
      is Some(cached) {
      println(@shell.wrap_for_shell(shell, cached))
      return
    }
  }

  // Compute prompt
  let prefix = if ctx.config.add_newline { "\n" } else { "" }
  let raw = prefix + render_prompt(ctx)
  ctx.close_repo()
  println(@shell.wrap_for_shell(shell, raw))

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
fn run_module(name : String, pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  let modules = build_modules(ctx.config)

  guard modules.get(name) is Some(m) else {
    println("moonship: unknown module '\{name}'")
    return
  }

  match m.execute(ctx) {
    Output(out) => println(out.render())
    Skipped(reason) => println("Module '\{name}' skipped: \{reason}")
    Disabled => println("Module '\{name}' is disabled")
  }

  ctx.close_repo()
}

///|
fn run_module_list() -> Unit {
  let modules = build_modules(@config.Config::default())
  let names = modules.keys().collect()
  names.sort()

  for name in names {
    println(name)
  }
}

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
fn run_help() -> Unit {
  let help =
    #|moonship - A fast async shell prompt
    #|
    #|Usage:
    #|  moonship prompt [options]    Generate prompt string
    #|  moonship timings [options]   Show module execution times
    #|  moonship module <name>       Run a single module
    #|  moonship module --list       List available modules
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
    #|  --keymap=<mode>           Vim keymap mode (vicmd, visual, replace)
    #|  --path=<path>             Override current directory
    #|  --shlvl=<n>               Shell nesting level
    #|  --async                   Recompute and update cache
    #|
    #|Supported shells: zsh, bash, fish
    #|
  println(help)
}
