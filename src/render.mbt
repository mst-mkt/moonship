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
  format~ : String = ctx.config.format,
  should_run~ : (&@ms.PromptModule) -> Bool = fn(_) { true },
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

    @ms.compose_segments(format, segment_vars).render()
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

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}
  modules["character"] = @mod_character.CharacterModule::from_config(config)
  modules["directory"] = @mod_directory.DirectoryModule::from_config(config)
  modules["git_branch"] = @mod_git_branch.GitBranchModule::from_config(config)
  modules["git_status"] = @mod_git_status.GitStatusModule::from_config(config)
  modules["cmd_duration"] = @mod_cmd_duration.CmdDurationModule::from_config(
    config,
  )
  modules["jobs"] = @mod_jobs.JobsModule::from_config(config)
  modules["line_break"] = @mod_line_break.LineBreakModule::from_config(config)
  modules["git_commit"] = @mod_git_commit.GitCommitModule::from_config(config)
  modules["git_state"] = @mod_git_state.GitStateModule::from_config(config)
  modules["package"] = @mod_package.PackageModule::from_config(config)
  modules["buf"] = @mod_buf.BufModule::from_config(config)
  modules["bun"] = @mod_bun.BunModule::from_config(config)
  modules["c"] = @mod_c.CModule::from_config(config)
  modules["cmake"] = @mod_cmake.CMakeModule::from_config(config)
  modules["cobol"] = @mod_cobol.CobolModule::from_config(config)
  modules["cpp"] = @mod_cpp.CppModule::from_config(config)
  modules["crystal"] = @mod_crystal.CrystalModule::from_config(config)
  modules["daml"] = @mod_daml.DamlModule::from_config(config)
  modules["dart"] = @mod_dart.DartModule::from_config(config)
  modules["docker_context"] = @mod_docker_context.DockerContextModule::from_config(
    config,
  )
  modules["deno"] = @mod_deno.DenoModule::from_config(config)
  modules["dotnet"] = @mod_dotnet.DotnetModule::from_config(config)
  modules["elixir"] = @mod_elixir.ElixirModule::from_config(config)
  modules["elm"] = @mod_elm.ElmModule::from_config(config)
  modules["erlang"] = @mod_erlang.ErlangModule::from_config(config)
  modules["fennel"] = @mod_fennel.FennelModule::from_config(config)
  modules["fortran"] = @mod_fortran.FortranModule::from_config(config)
  modules["gleam"] = @mod_gleam.GleamModule::from_config(config)
  modules["golang"] = @mod_golang.GolangModule::from_config(config)
  modules["gradle"] = @mod_gradle.GradleModule::from_config(config)
  modules["haskell"] = @mod_haskell.HaskellModule::from_config(config)
  modules["haxe"] = @mod_haxe.HaxeModule::from_config(config)
  modules["helm"] = @mod_helm.HelmModule::from_config(config)
  modules["hostname"] = @mod_hostname.HostnameModule::from_config(config)
  modules["java"] = @mod_java.JavaModule::from_config(config)
  modules["julia"] = @mod_julia.JuliaModule::from_config(config)
  modules["kotlin"] = @mod_kotlin.KotlinModule::from_config(config)
  modules["lua"] = @mod_lua.LuaModule::from_config(config)
  modules["maven"] = @mod_maven.MavenModule::from_config(config)
  modules["mojo"] = @mod_mojo.MojoModule::from_config(config)
  modules["moonbit"] = @mod_moonbit.MoonbitModule::from_config(config)
  modules["nim"] = @mod_nim.NimModule::from_config(config)
  modules["nodejs"] = @mod_nodejs.NodejsModule::from_config(config)
  modules["ocaml"] = @mod_ocaml.OCamlModule::from_config(config)
  modules["odin"] = @mod_odin.OdinModule::from_config(config)
  modules["opa"] = @mod_opa.OpaModule::from_config(config)
  modules["perl"] = @mod_perl.PerlModule::from_config(config)
  modules["php"] = @mod_php.PhpModule::from_config(config)
  modules["purescript"] = @mod_purescript.PureScriptModule::from_config(config)
  modules["python"] = @mod_python.PythonModule::from_config(config)
  modules["quarto"] = @mod_quarto.QuartoModule::from_config(config)
  modules["raku"] = @mod_raku.RakuModule::from_config(config)
  modules["red"] = @mod_red.RedModule::from_config(config)
  modules["rlang"] = @mod_rlang.RlangModule::from_config(config)
  modules["ruby"] = @mod_ruby.RubyModule::from_config(config)
  modules["shlvl"] = @mod_shlvl.ShlvlModule::from_config(config)
  modules["rust"] = @mod_rust.RustModule::from_config(config)
  modules["scala"] = @mod_scala.ScalaModule::from_config(config)
  modules["solidity"] = @mod_solidity.SolidityModule::from_config(config)
  modules["swift"] = @mod_swift.SwiftModule::from_config(config)
  modules["terraform"] = @mod_terraform.TerraformModule::from_config(config)
  modules["typst"] = @mod_typst.TypstModule::from_config(config)
  modules["username"] = @mod_username.UsernameModule::from_config(config)
  modules["vagrant"] = @mod_vagrant.VagrantModule::from_config(config)
  modules["vlang"] = @mod_vlang.VlangModule::from_config(config)
  modules["xmake"] = @mod_xmake.XmakeModule::from_config(config)
  modules["zig"] = @mod_zig.ZigModule::from_config(config)
  modules["localip"] = @mod_localip.LocalipModule::from_config(config)
  modules["kubernetes"] = @mod_kubernetes.KubernetesModule::from_config(config)
  modules["vcsh"] = @mod_vcsh.VcshModule::from_config(config)
  modules["fossil_branch"] = @mod_fossil_branch.FossilBranchModule::from_config(
    config,
  )
  modules["fossil_metrics"] = @mod_fossil_metrics.FossilMetricsModule::from_config(
    config,
  )
  modules["hg_branch"] = @mod_hg_branch.HgBranchModule::from_config(config)
  modules["hg_state"] = @mod_hg_state.HgStateModule::from_config(config)
  modules["pijul_channel"] = @mod_pijul_channel.PijulChannelModule::from_config(
    config,
  )
  modules["git_metrics"] = @mod_git_metrics.GitMetricsModule::from_config(
    config,
  )
  modules["singularity"] = @mod_singularity.SingularityModule::from_config(
    config,
  )
  modules["nats"] = @mod_nats.NatsModule::from_config(config)
  modules["openstack"] = @mod_openstack.OpenstackModule::from_config(config)
  modules["pulumi"] = @mod_pulumi.PulumiModule::from_config(config)
  modules["aws"] = @mod_aws.AwsModule::from_config(config)
  modules["gcloud"] = @mod_gcloud.GcloudModule::from_config(config)
  modules["azure"] = @mod_azure.AzureModule::from_config(config)
  modules["direnv"] = @mod_direnv.DirenvModule::from_config(config)
  modules["env_var"] = @mod_env_var.EnvVarModule::from_config(config)
  modules["mise"] = @mod_mise.MiseModule::from_config(config)
  modules["sudo"] = @mod_sudo.SudoModule::from_config(config)
  modules["os"] = @mod_os.OsModule::from_config(config)
  modules["shell"] = @mod_shell.ShellModule::from_config(config)
  modules["custom"] = @mod_custom.CustomModule::from_config(config)
  modules["guix_shell"] = @mod_guix_shell.GuixShellModule::from_config(config)
  modules["nix_shell"] = @mod_nix_shell.NixShellModule::from_config(config)
  modules["conda"] = @mod_conda.CondaModule::from_config(config)
  modules["pixi"] = @mod_pixi.PixiModule::from_config(config)
  modules["meson"] = @mod_meson.MesonModule::from_config(config)
  modules["spack"] = @mod_spack.SpackModule::from_config(config)
  modules["memory_usage"] = @mod_memory_usage.MemoryUsageModule::from_config(
    config,
  )
  modules["battery"] = @mod_battery.BatteryModule::from_config(config)
  modules["time"] = @mod_time.TimeModule::from_config(config)
  modules["netns"] = @mod_netns.NetnsModule::from_config(config)
  modules["status"] = @mod_status.StatusModule::from_config(config)
  modules["container"] = @mod_container.ContainerModule::from_config(config)
  modules
}

///|
fn collect_all_schemas() -> Array[@config.ModuleSchema] {
  [
    @mod_aws.AwsModule::schema(),
    @mod_azure.AzureModule::schema(),
    @mod_battery.BatteryModule::schema(),
    @mod_buf.BufModule::schema(),
    @mod_bun.BunModule::schema(),
    @mod_c.CModule::schema(),
    @mod_character.CharacterModule::schema(),
    @mod_cmake.CMakeModule::schema(),
    @mod_cmd_duration.CmdDurationModule::schema(),
    @mod_cobol.CobolModule::schema(),
    @mod_conda.CondaModule::schema(),
    @mod_container.ContainerModule::schema(),
    @mod_cpp.CppModule::schema(),
    @mod_crystal.CrystalModule::schema(),
    @mod_custom.CustomModule::schema(),
    @mod_daml.DamlModule::schema(),
    @mod_dart.DartModule::schema(),
    @mod_deno.DenoModule::schema(),
    @mod_directory.DirectoryModule::schema(),
    @mod_direnv.DirenvModule::schema(),
    @mod_docker_context.DockerContextModule::schema(),
    @mod_dotnet.DotnetModule::schema(),
    @mod_elixir.ElixirModule::schema(),
    @mod_elm.ElmModule::schema(),
    @mod_env_var.EnvVarModule::schema(),
    @mod_erlang.ErlangModule::schema(),
    @mod_fennel.FennelModule::schema(),
    @mod_fortran.FortranModule::schema(),
    @mod_fossil_branch.FossilBranchModule::schema(),
    @mod_fossil_metrics.FossilMetricsModule::schema(),
    @mod_gcloud.GcloudModule::schema(),
    @mod_git_branch.GitBranchModule::schema(),
    @mod_git_commit.GitCommitModule::schema(),
    @mod_git_metrics.GitMetricsModule::schema(),
    @mod_git_state.GitStateModule::schema(),
    @mod_git_status.GitStatusModule::schema(),
    @mod_gleam.GleamModule::schema(),
    @mod_golang.GolangModule::schema(),
    @mod_gradle.GradleModule::schema(),
    @mod_guix_shell.GuixShellModule::schema(),
    @mod_haskell.HaskellModule::schema(),
    @mod_haxe.HaxeModule::schema(),
    @mod_helm.HelmModule::schema(),
    @mod_hg_branch.HgBranchModule::schema(),
    @mod_hg_state.HgStateModule::schema(),
    @mod_hostname.HostnameModule::schema(),
    @mod_java.JavaModule::schema(),
    @mod_jobs.JobsModule::schema(),
    @mod_julia.JuliaModule::schema(),
    @mod_kotlin.KotlinModule::schema(),
    @mod_kubernetes.KubernetesModule::schema(),
    @mod_line_break.LineBreakModule::schema(),
    @mod_localip.LocalipModule::schema(),
    @mod_lua.LuaModule::schema(),
    @mod_maven.MavenModule::schema(),
    @mod_memory_usage.MemoryUsageModule::schema(),
    @mod_meson.MesonModule::schema(),
    @mod_mise.MiseModule::schema(),
    @mod_mojo.MojoModule::schema(),
    @mod_moonbit.MoonbitModule::schema(),
    @mod_nats.NatsModule::schema(),
    @mod_netns.NetnsModule::schema(),
    @mod_nim.NimModule::schema(),
    @mod_nix_shell.NixShellModule::schema(),
    @mod_nodejs.NodejsModule::schema(),
    @mod_ocaml.OCamlModule::schema(),
    @mod_odin.OdinModule::schema(),
    @mod_opa.OpaModule::schema(),
    @mod_openstack.OpenstackModule::schema(),
    @mod_os.OsModule::schema(),
    @mod_package.PackageModule::schema(),
    @mod_perl.PerlModule::schema(),
    @mod_php.PhpModule::schema(),
    @mod_pijul_channel.PijulChannelModule::schema(),
    @mod_pixi.PixiModule::schema(),
    @mod_pulumi.PulumiModule::schema(),
    @mod_purescript.PureScriptModule::schema(),
    @mod_python.PythonModule::schema(),
    @mod_quarto.QuartoModule::schema(),
    @mod_raku.RakuModule::schema(),
    @mod_red.RedModule::schema(),
    @mod_rlang.RlangModule::schema(),
    @mod_ruby.RubyModule::schema(),
    @mod_rust.RustModule::schema(),
    @mod_scala.ScalaModule::schema(),
    @mod_shell.ShellModule::schema(),
    @mod_shlvl.ShlvlModule::schema(),
    @mod_singularity.SingularityModule::schema(),
    @mod_solidity.SolidityModule::schema(),
    @mod_spack.SpackModule::schema(),
    @mod_status.StatusModule::schema(),
    @mod_sudo.SudoModule::schema(),
    @mod_swift.SwiftModule::schema(),
    @mod_terraform.TerraformModule::schema(),
    @mod_time.TimeModule::schema(),
    @mod_typst.TypstModule::schema(),
    @mod_username.UsernameModule::schema(),
    @mod_vagrant.VagrantModule::schema(),
    @mod_vcsh.VcshModule::schema(),
    @mod_vlang.VlangModule::schema(),
    @mod_xmake.XmakeModule::schema(),
    @mod_zig.ZigModule::schema(),
  ]
}
