///|
fn finalize_prompt(
  ctx : @context.Context,
  raw : String,
  shell : String,
  cache_key? : (String, Int)? = None,
) -> Unit {
  ctx.close_repo()
  println(@shell.wrap_for_shell(shell, raw))

  if cache_key is Some((cwd, status)) {
    @cache.write_prompt(cwd, status, raw)
  }
}

///|
async fn run_prompt(pa : PromptArgs) -> Unit {
  let shell = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)
  @terminal.set_active_palette(ctx.palette)

  match pa.target {
    Right => {
      guard not(ctx.config.right_format.is_empty()) else { return }
      let modules = build_modules(ctx.config)
      let raw = render_prompt(ctx, modules, format=ctx.config.right_format)
      return finalize_prompt(ctx, raw, shell)
    }
    Continuation => {
      let raw = render_continuation(ctx.config.continuation_prompt)
      println(@shell.wrap_for_shell(shell, raw))
      return
    }
    Profile(name) => {
      let format = ctx.config.profiles.get(name).unwrap_or("> ")
      let prefix = if ctx.config.add_newline { "\n" } else { "" }
      let modules = build_modules(ctx.config)
      let raw = prefix + render_prompt(ctx, modules, format~)
      return finalize_prompt(ctx, raw, shell)
    }
    Main => ()
  }

  let use_cache = (shell == "zsh" || shell == "fish") && pa.keymap.is_empty()

  if use_cache && not(pa.is_async) {
    if @cache.read_prompt(ctx.cwd, pa.status, ctx.config.cache_ttl)
      is Some(cached) {
      println(@shell.wrap_for_shell(shell, cached))
      return
    }
  }

  let prefix = if ctx.config.add_newline { "\n" } else { "" }
  let modules = build_modules(ctx.config)
  let has_async = modules.values().any(fn(m) { m.is_async() })

  let raw = if not(pa.is_async) && has_async {
    prefix + render_prompt(ctx, modules, should_run=fn(m) { not(m.is_async()) })
  } else {
    prefix + render_prompt(ctx, modules)
  }

  let cache_key : (String, Int)? = if use_cache &&
    (pa.is_async || not(has_async)) {
    Some((ctx.cwd, pa.status))
  } else {
    None
  }

  finalize_prompt(ctx, raw, shell, cache_key~)

  if pa.is_async && shell == "fish" {
    notify_parent() |> ignore
  }
}

///|
extern "C" fn notify_parent() -> Int = "moonship_notify_parent"

///|
fn run_session() -> Unit {
  let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  let charset_len = charset.length().reinterpret_as_uint()
  let now = @async.now().reinterpret_as_uint64()
  let seed = Bytes::makei(32, fn(i) {
    ((now >> (i % 8 * 8)) ^
    (i.reinterpret_as_uint().to_uint64() * 0x9E3779B97F4A7C15UL)).to_byte()
  })

  let rng = @random.Rand::chacha8(seed~)

  let result = StringBuilder::new()
  for _ in 0..<16 {
    let idx = rng.uint(limit=charset_len).reinterpret_as_int()
    result.write_char(charset[idx].unsafe_to_char())
  }

  println(result.to_string())
}

///|
async fn emit_warnings(warnings : Array[String]) -> Unit {
  for msg in warnings {
    @stdio.stderr.write("moonship: warning: \{msg}\n") catch {
      _ => ()
    }
  }
}

///|
async fn run_module(name : String, pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)
  @terminal.set_active_palette(ctx.palette)
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

  names.each(fn(name) { println(name) })
}

///|
async fn collect_module_entries(
  ctx : @context.Context,
  modules : Map[String, &@ms.PromptModule],
  skip_name? : (String) -> Bool = fn(_) { false },
  should_include~ : (Int64, String) -> Bool,
) -> Array[(String, Int64, String)] {
  let format = expand_all(ctx.config.format, modules)
  let module_names = @ms.extract_module_names(format)
  let entries : Array[(String, Int64, String)] = []

  for name in module_names {
    guard not(skip_name(name)) else { continue }
    guard modules.get(name) is Some(m) else { continue }

    let start = @async.now()
    let result = m.execute(ctx)
    let elapsed = @async.now() - start

    let output = match result {
      Output(out) => out.render().replace(old="\n", new="\\n")
      Skipped(_) | Disabled => ""
    }

    if should_include(elapsed, output) {
      entries.push((name, elapsed, output))
    }
  }

  ctx.close_repo()
  entries
}

///|
async fn run_timings(pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)
  @terminal.set_active_palette(ctx.palette)
  let modules = build_modules(ctx.config)

  let entries = collect_module_entries(ctx, modules, should_include=fn(
    elapsed,
    output,
  ) {
    elapsed > 0L || not(output.is_empty())
  })

  entries.sort_by(fn(a, b) { b.1.compare(a.1) })

  let max_name = max_length(entries.iter().map(fn(e) { e.0 }))
  let max_dur = max_length(entries.iter().map(fn(e) { format_duration(e.1) }))

  println("")
  println(" Here are the timings of modules in your prompt (>=1ms or output):")
  entries.each(fn(entry) {
    let (name, ms, output) = entry
    let dur = format_duration(ms)

    let async_marker = match modules.get(name) {
      Some(m) if m.is_async() => " [async]"
      _ => ""
    }

    println(
      " \{pad_right(name, max_name)}  -  \{pad_left(dur, max_dur)}  -   \"\{output}\"\{async_marker}",
    )
  })
}

///|
async fn run_explain(pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)
  @terminal.set_active_palette(ctx.palette)
  let modules = build_modules(ctx.config)

  let entries = collect_module_entries(
    ctx,
    modules,
    skip_name=fn(name) { name == "line_break" },
    should_include=fn(_elapsed, output) { not(output.is_empty()) },
  )

  let max_val_width = entries
    .iter()
    .fold(init=0, fn(max, e) {
      let w = e.2.length() + format_duration(e.1).length() + 6
      if w > max {
        w
      } else {
        max
      }
    })

  println("")
  println(" Here's a breakdown of your prompt:")
  entries.each(fn(entry) {
    let (name, ms, output) = entry
    let dur = format_duration(ms)
    let val_part = " \"\{output}\" (\{dur})"
    let padding = pad_right("", max_val_width - val_part.length() + 3)

    println("\{val_part}\{padding}-  \{module_description(name)}")
  })
}

///|
fn module_description(name : String) -> String {
  module_registry
  .iter()
  .find_first(fn(entry) { entry.name == name })
  .map(fn(entry) { entry.description })
  .unwrap_or("Unknown module")
}

///|
fn default_config_toml() -> String {
  let schemas = collect_all_schemas()
  let d = @config.Config::default()
  let buf = StringBuilder::new()

  buf.write_string("format = \{@config.escape_string(d.format)}\n")
  buf.write_string("right_format = \{@config.escape_string(d.right_format)}\n")
  buf.write_string(
    "continuation_prompt = \{@config.escape_string(d.continuation_prompt)}\n",
  )
  buf.write_string("scan_timeout = \{d.scan_timeout}\n")
  buf.write_string("command_timeout = \{d.command_timeout}\n")
  buf.write_string("cache_ttl = \{d.cache_ttl}\n")
  buf.write_string("add_newline = \{d.add_newline}\n")
  buf.write_string("follow_symlinks = \{d.follow_symlinks}\n")
  buf.write_string("palette = \{@config.escape_string(d.palette)}\n")

  for schema in schemas {
    buf.write_string("\n[\{schema.name}]\n")
    for field in schema.fields {
      let val = match field.field_type {
        @config.FString => @config.escape_string(field.default_value)
        _ => field.default_value
      }
      buf.write_string("\{field.name} = \{val}\n")
    }
  }

  buf.to_string()
}

///|
async fn run_config(name : String, value : String) -> Unit {
  if name.is_empty() {
    let editor = match @sys.get_env_var("VISUAL") {
      Some(v) => v
      None => @sys.get_env_var("EDITOR").unwrap_or("vi")
    }

    let config_path = {
      let env_path = @sys.get_env_var("MOONSHIP_CONFIG").unwrap_or("")
      if not(env_path.is_empty()) {
        env_path
      } else {
        let home = @sys.get_env_var("HOME").unwrap_or("")
        guard not(home.is_empty()) else { return }

        let dir = "\{home}/.config/moonship"
        let found = find_config_file(dir)
        if found.is_empty() {
          "\{dir}/moonship.toml"
        } else {
          found
        }
      }
    }

    ignore(@exec.exec_cmd(editor, [config_path]))
    return
  }

  let config = load_config()
  emit_warnings(config.warnings)

  if value.is_empty() {
    let parts = name.split(".").map(fn(s) { s.to_string() }).collect()

    if parts.length() == 1 {
      let key = parts[0]
      let result = match key {
        "format" => Some(config.format)
        "right_format" => Some(config.right_format)
        "continuation_prompt" => Some(config.continuation_prompt)
        "scan_timeout" => Some(config.scan_timeout.to_string())
        "command_timeout" => Some(config.command_timeout.to_string())
        "cache_ttl" => Some(config.cache_ttl.to_string())
        "add_newline" => Some(config.add_newline.to_string())
        "follow_symlinks" => Some(config.follow_symlinks.to_string())
        "palette" => Some(config.palette)
        "profiles" =>
          Some(
            config.profiles
            .iter()
            .map(fn(pair) { "\{pair.0} = \{@config.escape_string(pair.1)}" })
            .collect()
            .join("\n"),
          )
        _ =>
          config
          .get_raw_module(key)
          .map(fn(table) { module_to_toml_string(key, table) })
      }

      match result {
        Some(val) => println(val)
        None => println("moonship: key '\{name}' not found")
      }
    } else if parts.length() == 2 {
      let mod_name = parts[0]
      let key = parts[1]

      match config.get_raw_module(mod_name) {
        Some(table) =>
          match table.0.get(key) {
            Some(v) => println(config_value_display(v))
            None => println("moonship: key '\{name}' not found")
          }
        None => println("moonship: module '\{mod_name}' not found")
      }
    } else {
      println("moonship: invalid key '\{name}'")
    }
  } else {
    println("moonship: config editing by key is not yet supported")
    println("Please edit the config file directly.")
  }
}

///|
fn run_toggle(module_name : String, key : String) -> Unit {
  let config = load_config()

  match config.get_raw_module(module_name) {
    Some(table) =>
      match table.0.get(key) {
        Some(@config.CBool(current)) => {
          let new_val = not(current)
          println("Toggled \{module_name}.\{key}: \{current} -> \{new_val}")
          println("Note: To persist this change, add to your config file:")
          println("  [\{module_name}]")
          println("  \{key} = \{new_val}")
        }
        Some(_) =>
          println("moonship: '\{module_name}.\{key}' is not a boolean value")
        None =>
          println("moonship: key '\{key}' not found in module '\{module_name}'")
      }
    None => println("moonship: module '\{module_name}' not found in config")
  }
}

///|
fn module_to_toml_string(name : String, table : @config.ModuleTable) -> String {
  let keys = table.0.keys().collect()
  keys.sort()

  let lines : Array[String] = ["[\{name}]"]
  for key in keys {
    match table.0.get(key) {
      Some(v) => lines.push("\{key} = \{config_value_literal(v)}")
      None => ()
    }
  }

  lines.join("\n")
}

///|
fn config_value_display(v : @config.ConfigValue) -> String {
  match v {
    @config.CString(s) => s
    @config.CInt(n) => n.to_string()
    @config.CBool(b) => b.to_string()
    @config.CFloat(f) => f.to_string()
    _ => "..."
  }
}

///|
fn config_value_literal(v : @config.ConfigValue) -> String {
  match v {
    @config.CString(s) => @config.escape_string(s)
    @config.CInt(n) => n.to_string()
    @config.CBool(b) => b.to_string()
    @config.CFloat(f) => f.to_string()
    _ => "..."
  }
}

///|
async fn run_bug_report() -> Unit {
  let shell = @sys.get_env_var("SHELL").unwrap_or("unknown")
  let term = @sys.get_env_var("TERM").unwrap_or("unknown")
  let term_program = @sys.get_env_var("TERM_PROGRAM").unwrap_or("unknown")

  let os_info = {
    let out = @exec.exec_cmd("uname", ["-srm"])
    if out.is_empty() {
      "unknown"
    } else {
      out
    }
  }

  let config_path = {
    let env_path = @sys.get_env_var("MOONSHIP_CONFIG").unwrap_or("")
    if not(env_path.is_empty()) {
      env_path
    } else {
      let home = @sys.get_env_var("HOME").unwrap_or("")
      if home.is_empty() {
        "(none)"
      } else {
        find_config_file("\{home}/.config/moonship")
      }
    }
  }

  let config_contents = if config_path.is_empty() || config_path == "(none)" {
    "(no config file found)"
  } else {
    @fs.read_file_to_string(config_path) catch {
      _ => "(could not read)"
    }
  }

  println(
    [
      "#### Environment",
      "",
      "- **moonship version**: moonship 0.0.0",
      "- **Shell**: \{shell}",
      "- **Terminal**: \{term_program} (\{term})",
      {
        let os = os_info.trim_end(chars=" \n\r\t")
        "- **Operating System**: \{os}"
      },
      "",
      "#### Config",
      "",
      "**Config path**: `\{config_path}`",
      "",
      "```toml",
      config_contents,
      "```",
    ].join("\n"),
  )
}

///|
fn run_completions(shell_name : String) -> Unit {
  match shell_name {
    "zsh" => println(generate_zsh_completions())
    "bash" => println(generate_bash_completions())
    "fish" => println(generate_fish_completions())
    _ =>
      println(
        "moonship: unknown shell '\{shell_name}'. Supported: zsh, bash, fish",
      )
  }
}

///|
fn generate_zsh_completions() -> String {
  [
    "#compdef moonship", "", "_moonship() {", "  local -a commands", "  commands=(",
    "    'prompt:Generate prompt string'", "    'timings:Show module execution times'",
    "    'explain:Explain active modules'", "    'module:Run a single module'", "    'init:Print shell init script'",
    "    'cache:Cache operations'", "    'completions:Generate shell completions'",
    "    'session:Generate random session key'", "    'time:Print current time in ms'",
    "    'print-config:Print active configuration'", "    'schema:Print JSON Schema for config'",
    "    'version:Print version'", "    'help:Print help'", "  )", "", "  _describe 'command' commands",
    "}", "", "_moonship",
  ].join("\n")
}

///|
fn generate_bash_completions() -> String {
  [
    "_moonship() {", "  local cur=\"${COMP_WORDS[COMP_CWORD]}\"", "  local commands=\"prompt timings explain module init cache completions session time print-config schema version help\"",
    "", "  COMPREPLY=( $(compgen -W \"$commands\" -- \"$cur\") )", "}", "", "complete -F _moonship moonship",
  ].join("\n")
}

///|
fn generate_fish_completions() -> String {
  [
    "complete -c moonship -n '__fish_use_subcommand' -a prompt -d 'Generate prompt string'",
    "complete -c moonship -n '__fish_use_subcommand' -a timings -d 'Show module execution times'",
    "complete -c moonship -n '__fish_use_subcommand' -a explain -d 'Explain active modules'",
    "complete -c moonship -n '__fish_use_subcommand' -a module -d 'Run a single module'",
    "complete -c moonship -n '__fish_use_subcommand' -a init -d 'Print shell init script'",
    "complete -c moonship -n '__fish_use_subcommand' -a cache -d 'Cache operations'",
    "complete -c moonship -n '__fish_use_subcommand' -a completions -d 'Generate shell completions'",
    "complete -c moonship -n '__fish_use_subcommand' -a session -d 'Generate random session key'",
    "complete -c moonship -n '__fish_use_subcommand' -a time -d 'Print current time in ms'",
    "complete -c moonship -n '__fish_use_subcommand' -a print-config -d 'Print active configuration'",
    "complete -c moonship -n '__fish_use_subcommand' -a schema -d 'Print JSON Schema for config'",
    "complete -c moonship -n '__fish_use_subcommand' -a version -d 'Print version'",
    "complete -c moonship -n '__fish_use_subcommand' -a help -d 'Print help'",
  ].join("\n")
}

///|
fn run_init(shell_name : String, print_full : Bool) -> Unit {
  match @shell.Shell::from_string(shell_name) {
    Some(shell) => {
      let bin = self_exe()
      if print_full {
        println(@shell.generate_init(shell, bin))
      } else {
        println(@shell.generate_init_stub(shell, bin))
      }
    }
    None =>
      println(
        "moonship: unknown shell '\{shell_name}'. Supported: zsh, bash, fish",
      )
  }
}

///|
fn run_schema() -> Unit {
  let schemas = collect_all_schemas()
  println(@config.generate_json_schema(schemas))
}

///|
fn run_help() -> Unit {
  let help =
    #|moonship - A fast async shell prompt
    #|
    #|Usage:
    #|  moonship prompt [options]    Generate prompt string
    #|  moonship timings [options]   Show module execution times
    #|  moonship explain [options]   Explain active modules
    #|  moonship module <name>       Run a single module
    #|  moonship module --list       List available modules
    #|  moonship init <shell>        Print shell init stub
    #|    --print-full-init         Print full init script
    #|  moonship config               Edit config in $EDITOR
    #|  moonship toggle <name> [key] Toggle a module config value
    #|  moonship bug-report          Print environment info for bug reports
    #|  moonship completions <shell> Generate shell completions
    #|  moonship cache clear         Clear cached data
    #|  moonship session             Generate random session key
    #|  moonship time                Print current time in ms
    #|  moonship print-config        Print active configuration
    #|    --default, -d              Print default configuration
    #|  moonship schema              Print JSON Schema for config
    #|  moonship version             Print version
    #|  moonship help                Print this help
    #|
    #|Prompt options:
    #|  --status=<n>              Exit code of last command
    #|  --pipestatus=<codes>     Pipe status (space-delimited)
    #|  --cmd-duration=<ms>       Duration of last command
    #|  --jobs=<n>                Number of background jobs
    #|  --terminal-width=<cols>   Terminal width in columns
    #|  --keymap=<mode>           Vim keymap mode (vicmd, visual, replace)
    #|  --path=<path>             Override current directory
    #|  --logical-path=<path>    Logical path for display
    #|  --shlvl=<n>               Shell nesting level
    #|  --right                   Print the right prompt
    #|  --continuation            Print continuation prompt
    #|  --profile=<name>         Use a named profile format
    #|  --async                   Recompute and update cache
    #|
    #|Supported shells: zsh, bash, fish
    #|
  println(help)
}
