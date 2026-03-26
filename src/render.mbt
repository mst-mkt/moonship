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
fn replace_var(s : String, var_name : String, replacement : String) -> String {
  let target = "$\{var_name}"
  let buf = StringBuilder::new()
  let len = s.length()
  let target_len = target.length()

  loop 0 {
    i =>
      if i >= len {
        break buf.to_string()
      } else if s[i].unsafe_to_char() == '$' && starts_with_at(s, i, target) {
        let after = i + target_len
        if after >= len || not(is_ident_char(s[after].unsafe_to_char())) {
          buf.write_string(replacement)
          continue after
        } else {
          buf.write_char(s[i].unsafe_to_char())
          continue i + 1
        }
      } else {
        buf.write_char(s[i].unsafe_to_char())
        continue i + 1
      }
  }
}

///|
fn starts_with_at(s : String, offset : Int, prefix : String) -> Bool {
  let prefix_len = prefix.length()

  if offset + prefix_len > s.length() {
    return false
  }

  loop 0 {
    j =>
      if j >= prefix_len {
        break true
      } else if s[offset + j] != prefix[j] {
        break false
      } else {
        continue j + 1
      }
  }
}

///|
fn is_ident_char(c : Char) -> Bool {
  match c {
    'a'..='z' | 'A'..='Z' | '_' | '0'..='9' => true
    _ => false
  }
}

