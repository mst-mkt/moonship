///|
let module_order : Array[String] = [
  "username", "hostname", "localip", "shlvl", "singularity", "kubernetes", "nats",
  "directory", "vcsh", "fossil_branch", "fossil_metrics", "git_branch", "git_commit",
  "git_state", "git_metrics", "git_status", "hg_branch", "hg_state", "pijul_channel",
  "docker_context", "package", "bun", "c", "cmake", "cobol", "cpp", "daml", "dart",
  "deno", "dotnet", "elixir", "elm", "erlang", "fennel", "fortran", "gleam", "golang",
  "gradle", "haskell", "haxe", "helm", "java", "julia", "kotlin", "lua", "maven",
  "mojo", "moonbit", "nim", "nodejs", "ocaml", "odin", "opa", "perl", "php", "pulumi",
  "purescript", "python", "quarto", "raku", "rlang", "red", "ruby", "rust", "scala",
  "solidity", "swift", "terraform", "typst", "vlang", "vagrant", "xmake", "zig",
  "buf", "guix_shell", "nix_shell", "conda", "pixi", "meson", "spack", "memory_usage",
  "aws", "gcloud", "openstack", "azure", "direnv", "env_var", "mise", "crystal",
  "custom", "sudo", "cmd_duration", "line_break", "jobs", "battery", "time", "status",
  "container", "netns", "os", "shell", "character",
]

///|
fn render_continuation(format : String) -> String {
  let vars : Map[String, String] = {}
  let segments = @ms.format_string(format, vars, @terminal.Style::default())
  @ms.ModuleOutput::new(segments).render()
}

///|
async fn render_prompt(
  ctx : @context.Context,
  modules : Map[String, &@ms.PromptModule],
  format? : String = ctx.config.format,
  should_run? : (&@ms.PromptModule) -> Bool = fn(_) { true },
) -> String {
  let format = expand_all(format, modules)
  let format = expand_prefixed_modules(format, modules)
  let names = @ms.extract_module_names(format)
  let segment_vars : Map[String, Array[@ms.Segment]] = {}

  // Pre-resolve git repo before spawning concurrent tasks
  ignore(ctx.get_repo())

  @async.with_task_group(async fn(group) {
    let tasks : Array[(String, @async.Task[@ms.ModuleResult])] = []

    for name in names {
      guard modules.get(name) is Some(m) else { continue }
      guard should_run(m) else { continue }
      let task = group.spawn(async fn() { m.execute(ctx) }, allow_failure=true)
      tasks.push((name, task))
    }

    for pair in tasks {
      let (name, task) = pair
      guard task.wait() is Output(output) else { continue }
      segment_vars[name] = output.segments
    }

    let palette = ctx.config.get_active_palette()
    let output = @ms.compose_segments(format, segment_vars, palette~)
    output.render_with_fill(ctx.terminal_width)
  })
}

///|
fn expand_all(
  format : String,
  modules : Map[String, &@ms.PromptModule],
) -> String {
  guard format.contains("$all") else { return format }

  let explicit = @ms.extract_module_names(format)
    .iter()
    .filter(fn(name) { name != "all" })
    .fold(init=Map::new(), fn(set, name) {
      set[name] = true
      set
    })

  let expansion = module_order
    .iter()
    .filter(fn(name) { modules.contains(name) && not(explicit.contains(name)) })
    .map(fn(name) { "$\{name}" })
    .collect()
    .join("")

  replace_var(format, "all", expansion)
}

///|
/// Replace `$env_var` and `$custom` with their child instances when children
/// exist in the config (e.g., `$env_var` → `${env_var.VIMSHELL}${env_var.HOME}`).
fn expand_prefixed_modules(
  format : String,
  modules : Map[String, &@ms.PromptModule],
) -> String {
  let prefixes : Array[String] = ["env_var", "custom"]

  prefixes
  .iter()
  .fold(init=format, fn(fmt, prefix) {
    guard fmt.contains("$\{prefix}") else { return fmt }

    let children : Array[String] = modules
      .keys()
      .collect()
      .iter()
      .filter(fn(name) { name.has_prefix("\{prefix}.") })
      .collect()

    guard not(children.is_empty()) else { return fmt }

    children.sort()

    let expansion = children
      .iter()
      .map(fn(name) { "${\{name}}" })
      .collect()
      .join("")

    replace_var(fmt, prefix, expansion)
  })
}

///|
fn replace_var(s : String, var_name : String, replacement : String) -> String {
  let target = "$\{var_name}"

  guard s.contains(target) else { return s }

  let parts = s.split(target).map(fn(v) { v.to_string() }).collect()

  parts
  .foldi(init=StringBuilder::new(), fn(i, buf, part) {
    if i > 0 {
      let next_is_ident = not(part.is_empty()) &&
        @ms.is_ident_char(part[0].unsafe_to_char())

      if next_is_ident {
        buf.write_string(target)
      } else {
        buf.write_string(replacement)
      }
    }

    buf.write_string(part)
    buf
  })
  .to_string()
}
