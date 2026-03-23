///|
async fn run_prompt(pa : PromptArgs) -> Unit {
  let shell = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  let use_cache = (shell == "zsh" || shell == "fish") && pa.keymap.is_empty()
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)

  // Cache hit: return immediately (sync path only)
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

  if pa.is_async {
    let raw = prefix + render_prompt(ctx, modules)
    ctx.close_repo()
    println(@shell.wrap_for_shell(shell, raw))

    if use_cache {
      @cache.write_prompt(ctx.cwd, pa.status, raw)
    }

    if shell == "fish" {
      notify_parent() |> ignore
    }
  } else if has_async {
    let raw = prefix + render_prompt_sync(ctx, modules)
    ctx.close_repo()
    println(@shell.wrap_for_shell(shell, raw))
  } else {
    let raw = prefix + render_prompt(ctx, modules)
    ctx.close_repo()
    println(@shell.wrap_for_shell(shell, raw))

    if use_cache {
      @cache.write_prompt(ctx.cwd, pa.status, raw)
    }
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
    ((now >> ((i % 8) * 8)) ^ (i.reinterpret_as_uint().to_uint64() * 0x9E3779B97F4A7C15UL)).to_byte()
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
async fn run_timings(pa : PromptArgs) -> Unit {
  let ctx = build_context(pa)
  emit_warnings(ctx.config.warnings)
  let modules = build_modules(ctx.config)
  let format = expand_all(ctx.config.format, modules)
  let module_names = @ms.extract_module_names(format)

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
  let modules = build_modules(ctx.config)
  let format = expand_all(ctx.config.format, modules)
  let module_names = @ms.extract_module_names(format)

  let entries : Array[(String, Int64, String)] = []

  for name in module_names {
    guard name != "line_break" else { continue }
    guard modules.get(name) is Some(m) else { continue }

    let start = @async.now()
    let result = m.execute(ctx)
    let elapsed = @async.now() - start

    let output = match result {
      Output(out) => out.render().replace(old="\n", new="\\n")
      Skipped(_) | Disabled => ""
    }

    if not(output.is_empty()) {
      entries.push((name, elapsed, output))
    }
  }

  ctx.close_repo()

  let max_val_width = entries.iter().fold(init=0, fn(max, e) {
    let w = e.2.length() + format_duration(e.1).length() + 6
    if w > max { w } else { max }
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
  match name {
    "aws" => "The current AWS region and profile"
    "azure" => "The current Azure subscription"
    "battery" => "The current charge and status of the battery"
    "buf" => "The currently installed version of the Buf CLI"
    "bun" => "The currently installed version of Bun"
    "c" => "The currently installed version of C compiler"
    "character" =>
      "A character beside where the text is entered in your terminal"
    "cmake" => "The currently installed version of CMake"
    "cmd_duration" => "How long the last command took to execute"
    "cobol" => "The currently installed version of COBOL"
    "conda" => "The current Conda environment"
    "container" => "The current container indicator"
    "cpp" => "The currently installed version of C++ compiler"
    "crystal" => "The currently installed version of Crystal"
    "custom" => "A custom module"
    "daml" => "The currently installed version of DAML"
    "dart" => "The currently installed version of Dart"
    "deno" => "The currently installed version of Deno"
    "directory" => "The current working directory"
    "direnv" => "The current direnv status"
    "docker_context" => "The current Docker context"
    "dotnet" => "The currently installed version of .NET"
    "elixir" => "The currently installed version of Elixir"
    "elm" => "The currently installed version of Elm"
    "env_var" => "A configured environment variable"
    "erlang" => "The currently installed version of Erlang"
    "fennel" => "The currently installed version of Fennel"
    "fortran" => "The currently installed version of Fortran"
    "fossil_branch" => "The current Fossil branch"
    "fossil_metrics" => "The current Fossil metrics"
    "gcloud" => "The current GCP project and region"
    "git_branch" => "The current Git branch"
    "git_commit" => "The current Git commit hash"
    "git_metrics" => "The current Git added/deleted lines"
    "git_state" => "The current Git operation state"
    "git_status" => "Symbol representing the state of the repo"
    "gleam" => "The currently installed version of Gleam"
    "golang" => "The currently installed version of Go"
    "gradle" => "The currently installed version of Gradle"
    "guix_shell" => "The current Guix shell environment"
    "haskell" => "The currently installed version of Haskell"
    "haxe" => "The currently installed version of Haxe"
    "helm" => "The currently installed version of Helm"
    "hg_branch" => "The current Mercurial branch"
    "hg_state" => "The current Mercurial operation state"
    "hostname" => "The current hostname"
    "java" => "The currently installed version of Java"
    "jobs" => "The current number of background jobs"
    "julia" => "The currently installed version of Julia"
    "kotlin" => "The currently installed version of Kotlin"
    "kubernetes" => "The current Kubernetes context and namespace"
    "line_break" => "Separates the prompt into two lines"
    "localip" => "The current local IP address"
    "lua" => "The currently installed version of Lua"
    "maven" => "The currently installed version of Maven"
    "memory_usage" => "Current system memory and swap usage"
    "meson" => "The current Meson dev environment"
    "mise" => "The current mise tool versions"
    "mojo" => "The currently installed version of Mojo"
    "moonbit" => "The currently installed version of MoonBit"
    "nats" => "The current NATS context"
    "netns" => "The current network namespace"
    "nim" => "The currently installed version of Nim"
    "nix_shell" => "The current Nix shell environment"
    "nodejs" => "The currently installed version of Node.js"
    "ocaml" => "The currently installed version of OCaml"
    "odin" => "The currently installed version of Odin"
    "opa" => "The currently installed version of OPA"
    "openstack" => "The current OpenStack cloud and project"
    "os" => "The current operating system"
    "package" => "The current package version"
    "perl" => "The currently installed version of Perl"
    "php" => "The currently installed version of PHP"
    "pijul_channel" => "The current Pijul channel"
    "pixi" => "The current Pixi environment"
    "pulumi" => "The current Pulumi stack and version"
    "purescript" => "The currently installed version of PureScript"
    "python" => "The currently installed version of Python"
    "quarto" => "The currently installed version of Quarto"
    "raku" => "The currently installed version of Raku"
    "red" => "The currently installed version of Red"
    "rlang" => "The currently installed version of R"
    "ruby" => "The currently installed version of Ruby"
    "rust" => "The currently installed version of Rust"
    "scala" => "The currently installed version of Scala"
    "shell" => "The current shell indicator"
    "shlvl" => "The current shell level"
    "singularity" => "The current Singularity image"
    "solidity" => "The currently installed version of Solidity"
    "spack" => "The current Spack environment"
    "status" => "The exit code of the last command"
    "sudo" => "The current sudo credentials status"
    "swift" => "The currently installed version of Swift"
    "terraform" => "The current Terraform workspace and version"
    "time" => "The current local time"
    "typst" => "The currently installed version of Typst"
    "username" => "The current username"
    "vagrant" => "The currently installed version of Vagrant"
    "vcsh" => "The current VCSH repository"
    "vlang" => "The currently installed version of V"
    "xmake" => "The currently installed version of XMake"
    "zig" => "The currently installed version of Zig"
    _ => "Unknown module"
  }
}

///|
fn default_config_toml() -> String {
  let schemas = collect_all_schemas()
  let d = @config.Config::default()
  let buf = StringBuilder::new()

  buf.write_string("format = \{@config.escape_string(d.format)}\n")
  buf.write_string("scan_timeout = \{d.scan_timeout}\n")
  buf.write_string("command_timeout = \{d.command_timeout}\n")
  buf.write_string("cache_ttl = \{d.cache_ttl}\n")
  buf.write_string("add_newline = \{d.add_newline}\n")

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
    #|  --async                   Recompute and update cache
    #|
    #|Supported shells: zsh, bash, fish
    #|
  println(help)
}
