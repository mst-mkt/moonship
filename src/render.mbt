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

///|
struct ModuleEntry {
  name : String
  create : (@config.Config) -> &@ms.PromptModule
  schema : () -> @config.ModuleSchema
  description : String
}

///|
let module_registry : Array[ModuleEntry] = [
  { name: "aws", create: fn(c) { @mod_aws.AwsModule::from_config(c) }, schema: @mod_aws.AwsModule::schema, description: "The current AWS region and profile" },
  { name: "azure", create: fn(c) { @mod_azure.AzureModule::from_config(c) }, schema: @mod_azure.AzureModule::schema, description: "The current Azure subscription" },
  { name: "battery", create: fn(c) { @mod_battery.BatteryModule::from_config(c) }, schema: @mod_battery.BatteryModule::schema, description: "The current charge and status of the battery" },
  { name: "buf", create: fn(c) { @mod_buf.BufModule::from_config(c) }, schema: @mod_buf.BufModule::schema, description: "The currently installed version of the Buf CLI" },
  { name: "bun", create: fn(c) { @mod_bun.BunModule::from_config(c) }, schema: @mod_bun.BunModule::schema, description: "The currently installed version of Bun" },
  { name: "c", create: fn(c) { @mod_c.CModule::from_config(c) }, schema: @mod_c.CModule::schema, description: "The currently installed version of C compiler" },
  { name: "character", create: fn(c) { @mod_character.CharacterModule::from_config(c) }, schema: @mod_character.CharacterModule::schema, description: "A character beside where the text is entered in your terminal" },
  { name: "cmake", create: fn(c) { @mod_cmake.CMakeModule::from_config(c) }, schema: @mod_cmake.CMakeModule::schema, description: "The currently installed version of CMake" },
  { name: "cmd_duration", create: fn(c) { @mod_cmd_duration.CmdDurationModule::from_config(c) }, schema: @mod_cmd_duration.CmdDurationModule::schema, description: "How long the last command took to execute" },
  { name: "cobol", create: fn(c) { @mod_cobol.CobolModule::from_config(c) }, schema: @mod_cobol.CobolModule::schema, description: "The currently installed version of COBOL" },
  { name: "conda", create: fn(c) { @mod_conda.CondaModule::from_config(c) }, schema: @mod_conda.CondaModule::schema, description: "The current Conda environment" },
  { name: "container", create: fn(c) { @mod_container.ContainerModule::from_config(c) }, schema: @mod_container.ContainerModule::schema, description: "The current container indicator" },
  { name: "cpp", create: fn(c) { @mod_cpp.CppModule::from_config(c) }, schema: @mod_cpp.CppModule::schema, description: "The currently installed version of C++ compiler" },
  { name: "crystal", create: fn(c) { @mod_crystal.CrystalModule::from_config(c) }, schema: @mod_crystal.CrystalModule::schema, description: "The currently installed version of Crystal" },
  { name: "custom", create: fn(c) { @mod_custom.CustomModule::from_config(c) }, schema: @mod_custom.CustomModule::schema, description: "A custom module" },
  { name: "daml", create: fn(c) { @mod_daml.DamlModule::from_config(c) }, schema: @mod_daml.DamlModule::schema, description: "The currently installed version of DAML" },
  { name: "dart", create: fn(c) { @mod_dart.DartModule::from_config(c) }, schema: @mod_dart.DartModule::schema, description: "The currently installed version of Dart" },
  { name: "deno", create: fn(c) { @mod_deno.DenoModule::from_config(c) }, schema: @mod_deno.DenoModule::schema, description: "The currently installed version of Deno" },
  { name: "directory", create: fn(c) { @mod_directory.DirectoryModule::from_config(c) }, schema: @mod_directory.DirectoryModule::schema, description: "The current working directory" },
  { name: "direnv", create: fn(c) { @mod_direnv.DirenvModule::from_config(c) }, schema: @mod_direnv.DirenvModule::schema, description: "The current direnv status" },
  { name: "docker_context", create: fn(c) { @mod_docker_context.DockerContextModule::from_config(c) }, schema: @mod_docker_context.DockerContextModule::schema, description: "The current Docker context" },
  { name: "dotnet", create: fn(c) { @mod_dotnet.DotnetModule::from_config(c) }, schema: @mod_dotnet.DotnetModule::schema, description: "The currently installed version of .NET" },
  { name: "elixir", create: fn(c) { @mod_elixir.ElixirModule::from_config(c) }, schema: @mod_elixir.ElixirModule::schema, description: "The currently installed version of Elixir" },
  { name: "elm", create: fn(c) { @mod_elm.ElmModule::from_config(c) }, schema: @mod_elm.ElmModule::schema, description: "The currently installed version of Elm" },
  { name: "env_var", create: fn(c) { @mod_env_var.EnvVarModule::from_config(c) }, schema: @mod_env_var.EnvVarModule::schema, description: "A configured environment variable" },
  { name: "erlang", create: fn(c) { @mod_erlang.ErlangModule::from_config(c) }, schema: @mod_erlang.ErlangModule::schema, description: "The currently installed version of Erlang" },
  { name: "fennel", create: fn(c) { @mod_fennel.FennelModule::from_config(c) }, schema: @mod_fennel.FennelModule::schema, description: "The currently installed version of Fennel" },
  { name: "fill", create: fn(c) { @mod_fill.FillModule::from_config(c) }, schema: @mod_fill.FillModule::schema, description: "Fill the remaining space on the line" },
  { name: "fortran", create: fn(c) { @mod_fortran.FortranModule::from_config(c) }, schema: @mod_fortran.FortranModule::schema, description: "The currently installed version of Fortran" },
  { name: "fossil_branch", create: fn(c) { @mod_fossil_branch.FossilBranchModule::from_config(c) }, schema: @mod_fossil_branch.FossilBranchModule::schema, description: "The current Fossil branch" },
  { name: "fossil_metrics", create: fn(c) { @mod_fossil_metrics.FossilMetricsModule::from_config(c) }, schema: @mod_fossil_metrics.FossilMetricsModule::schema, description: "The current Fossil metrics" },
  { name: "gcloud", create: fn(c) { @mod_gcloud.GcloudModule::from_config(c) }, schema: @mod_gcloud.GcloudModule::schema, description: "The current GCP project and region" },
  { name: "git_branch", create: fn(c) { @mod_git_branch.GitBranchModule::from_config(c) }, schema: @mod_git_branch.GitBranchModule::schema, description: "The current Git branch" },
  { name: "git_commit", create: fn(c) { @mod_git_commit.GitCommitModule::from_config(c) }, schema: @mod_git_commit.GitCommitModule::schema, description: "The current Git commit hash" },
  { name: "git_metrics", create: fn(c) { @mod_git_metrics.GitMetricsModule::from_config(c) }, schema: @mod_git_metrics.GitMetricsModule::schema, description: "The current Git added/deleted lines" },
  { name: "git_state", create: fn(c) { @mod_git_state.GitStateModule::from_config(c) }, schema: @mod_git_state.GitStateModule::schema, description: "The current Git operation state" },
  { name: "git_status", create: fn(c) { @mod_git_status.GitStatusModule::from_config(c) }, schema: @mod_git_status.GitStatusModule::schema, description: "Symbol representing the state of the repo" },
  { name: "gleam", create: fn(c) { @mod_gleam.GleamModule::from_config(c) }, schema: @mod_gleam.GleamModule::schema, description: "The currently installed version of Gleam" },
  { name: "golang", create: fn(c) { @mod_golang.GolangModule::from_config(c) }, schema: @mod_golang.GolangModule::schema, description: "The currently installed version of Go" },
  { name: "gradle", create: fn(c) { @mod_gradle.GradleModule::from_config(c) }, schema: @mod_gradle.GradleModule::schema, description: "The currently installed version of Gradle" },
  { name: "guix_shell", create: fn(c) { @mod_guix_shell.GuixShellModule::from_config(c) }, schema: @mod_guix_shell.GuixShellModule::schema, description: "The current Guix shell environment" },
  { name: "haskell", create: fn(c) { @mod_haskell.HaskellModule::from_config(c) }, schema: @mod_haskell.HaskellModule::schema, description: "The currently installed version of Haskell" },
  { name: "haxe", create: fn(c) { @mod_haxe.HaxeModule::from_config(c) }, schema: @mod_haxe.HaxeModule::schema, description: "The currently installed version of Haxe" },
  { name: "helm", create: fn(c) { @mod_helm.HelmModule::from_config(c) }, schema: @mod_helm.HelmModule::schema, description: "The currently installed version of Helm" },
  { name: "hg_branch", create: fn(c) { @mod_hg_branch.HgBranchModule::from_config(c) }, schema: @mod_hg_branch.HgBranchModule::schema, description: "The current Mercurial branch" },
  { name: "hg_state", create: fn(c) { @mod_hg_state.HgStateModule::from_config(c) }, schema: @mod_hg_state.HgStateModule::schema, description: "The current Mercurial operation state" },
  { name: "hostname", create: fn(c) { @mod_hostname.HostnameModule::from_config(c) }, schema: @mod_hostname.HostnameModule::schema, description: "The current hostname" },
  { name: "java", create: fn(c) { @mod_java.JavaModule::from_config(c) }, schema: @mod_java.JavaModule::schema, description: "The currently installed version of Java" },
  { name: "jobs", create: fn(c) { @mod_jobs.JobsModule::from_config(c) }, schema: @mod_jobs.JobsModule::schema, description: "The current number of background jobs" },
  { name: "julia", create: fn(c) { @mod_julia.JuliaModule::from_config(c) }, schema: @mod_julia.JuliaModule::schema, description: "The currently installed version of Julia" },
  { name: "kotlin", create: fn(c) { @mod_kotlin.KotlinModule::from_config(c) }, schema: @mod_kotlin.KotlinModule::schema, description: "The currently installed version of Kotlin" },
  { name: "kubernetes", create: fn(c) { @mod_kubernetes.KubernetesModule::from_config(c) }, schema: @mod_kubernetes.KubernetesModule::schema, description: "The current Kubernetes context and namespace" },
  { name: "line_break", create: fn(c) { @mod_line_break.LineBreakModule::from_config(c) }, schema: @mod_line_break.LineBreakModule::schema, description: "Separates the prompt into two lines" },
  { name: "localip", create: fn(c) { @mod_localip.LocalipModule::from_config(c) }, schema: @mod_localip.LocalipModule::schema, description: "The current local IP address" },
  { name: "lua", create: fn(c) { @mod_lua.LuaModule::from_config(c) }, schema: @mod_lua.LuaModule::schema, description: "The currently installed version of Lua" },
  { name: "maven", create: fn(c) { @mod_maven.MavenModule::from_config(c) }, schema: @mod_maven.MavenModule::schema, description: "The currently installed version of Maven" },
  { name: "memory_usage", create: fn(c) { @mod_memory_usage.MemoryUsageModule::from_config(c) }, schema: @mod_memory_usage.MemoryUsageModule::schema, description: "Current system memory and swap usage" },
  { name: "meson", create: fn(c) { @mod_meson.MesonModule::from_config(c) }, schema: @mod_meson.MesonModule::schema, description: "The current Meson dev environment" },
  { name: "mise", create: fn(c) { @mod_mise.MiseModule::from_config(c) }, schema: @mod_mise.MiseModule::schema, description: "The current mise tool versions" },
  { name: "mojo", create: fn(c) { @mod_mojo.MojoModule::from_config(c) }, schema: @mod_mojo.MojoModule::schema, description: "The currently installed version of Mojo" },
  { name: "moonbit", create: fn(c) { @mod_moonbit.MoonbitModule::from_config(c) }, schema: @mod_moonbit.MoonbitModule::schema, description: "The currently installed version of MoonBit" },
  { name: "nats", create: fn(c) { @mod_nats.NatsModule::from_config(c) }, schema: @mod_nats.NatsModule::schema, description: "The current NATS context" },
  { name: "netns", create: fn(c) { @mod_netns.NetnsModule::from_config(c) }, schema: @mod_netns.NetnsModule::schema, description: "The current network namespace" },
  { name: "nim", create: fn(c) { @mod_nim.NimModule::from_config(c) }, schema: @mod_nim.NimModule::schema, description: "The currently installed version of Nim" },
  { name: "nix_shell", create: fn(c) { @mod_nix_shell.NixShellModule::from_config(c) }, schema: @mod_nix_shell.NixShellModule::schema, description: "The current Nix shell environment" },
  { name: "nodejs", create: fn(c) { @mod_nodejs.NodejsModule::from_config(c) }, schema: @mod_nodejs.NodejsModule::schema, description: "The currently installed version of Node.js" },
  { name: "ocaml", create: fn(c) { @mod_ocaml.OCamlModule::from_config(c) }, schema: @mod_ocaml.OCamlModule::schema, description: "The currently installed version of OCaml" },
  { name: "odin", create: fn(c) { @mod_odin.OdinModule::from_config(c) }, schema: @mod_odin.OdinModule::schema, description: "The currently installed version of Odin" },
  { name: "opa", create: fn(c) { @mod_opa.OpaModule::from_config(c) }, schema: @mod_opa.OpaModule::schema, description: "The currently installed version of OPA" },
  { name: "openstack", create: fn(c) { @mod_openstack.OpenstackModule::from_config(c) }, schema: @mod_openstack.OpenstackModule::schema, description: "The current OpenStack cloud and project" },
  { name: "os", create: fn(c) { @mod_os.OsModule::from_config(c) }, schema: @mod_os.OsModule::schema, description: "The current operating system" },
  { name: "package", create: fn(c) { @mod_package.PackageModule::from_config(c) }, schema: @mod_package.PackageModule::schema, description: "The current package version" },
  { name: "perl", create: fn(c) { @mod_perl.PerlModule::from_config(c) }, schema: @mod_perl.PerlModule::schema, description: "The currently installed version of Perl" },
  { name: "php", create: fn(c) { @mod_php.PhpModule::from_config(c) }, schema: @mod_php.PhpModule::schema, description: "The currently installed version of PHP" },
  { name: "pijul_channel", create: fn(c) { @mod_pijul_channel.PijulChannelModule::from_config(c) }, schema: @mod_pijul_channel.PijulChannelModule::schema, description: "The current Pijul channel" },
  { name: "pixi", create: fn(c) { @mod_pixi.PixiModule::from_config(c) }, schema: @mod_pixi.PixiModule::schema, description: "The current Pixi environment" },
  { name: "pulumi", create: fn(c) { @mod_pulumi.PulumiModule::from_config(c) }, schema: @mod_pulumi.PulumiModule::schema, description: "The current Pulumi stack and version" },
  { name: "purescript", create: fn(c) { @mod_purescript.PureScriptModule::from_config(c) }, schema: @mod_purescript.PureScriptModule::schema, description: "The currently installed version of PureScript" },
  { name: "python", create: fn(c) { @mod_python.PythonModule::from_config(c) }, schema: @mod_python.PythonModule::schema, description: "The currently installed version of Python" },
  { name: "quarto", create: fn(c) { @mod_quarto.QuartoModule::from_config(c) }, schema: @mod_quarto.QuartoModule::schema, description: "The currently installed version of Quarto" },
  { name: "raku", create: fn(c) { @mod_raku.RakuModule::from_config(c) }, schema: @mod_raku.RakuModule::schema, description: "The currently installed version of Raku" },
  { name: "red", create: fn(c) { @mod_red.RedModule::from_config(c) }, schema: @mod_red.RedModule::schema, description: "The currently installed version of Red" },
  { name: "rlang", create: fn(c) { @mod_rlang.RlangModule::from_config(c) }, schema: @mod_rlang.RlangModule::schema, description: "The currently installed version of R" },
  { name: "ruby", create: fn(c) { @mod_ruby.RubyModule::from_config(c) }, schema: @mod_ruby.RubyModule::schema, description: "The currently installed version of Ruby" },
  { name: "rust", create: fn(c) { @mod_rust.RustModule::from_config(c) }, schema: @mod_rust.RustModule::schema, description: "The currently installed version of Rust" },
  { name: "scala", create: fn(c) { @mod_scala.ScalaModule::from_config(c) }, schema: @mod_scala.ScalaModule::schema, description: "The currently installed version of Scala" },
  { name: "shell", create: fn(c) { @mod_shell.ShellModule::from_config(c) }, schema: @mod_shell.ShellModule::schema, description: "The current shell indicator" },
  { name: "shlvl", create: fn(c) { @mod_shlvl.ShlvlModule::from_config(c) }, schema: @mod_shlvl.ShlvlModule::schema, description: "The current shell level" },
  { name: "singularity", create: fn(c) { @mod_singularity.SingularityModule::from_config(c) }, schema: @mod_singularity.SingularityModule::schema, description: "The current Singularity image" },
  { name: "solidity", create: fn(c) { @mod_solidity.SolidityModule::from_config(c) }, schema: @mod_solidity.SolidityModule::schema, description: "The currently installed version of Solidity" },
  { name: "spack", create: fn(c) { @mod_spack.SpackModule::from_config(c) }, schema: @mod_spack.SpackModule::schema, description: "The current Spack environment" },
  { name: "status", create: fn(c) { @mod_status.StatusModule::from_config(c) }, schema: @mod_status.StatusModule::schema, description: "The exit code of the last command" },
  { name: "sudo", create: fn(c) { @mod_sudo.SudoModule::from_config(c) }, schema: @mod_sudo.SudoModule::schema, description: "The current sudo credentials status" },
  { name: "swift", create: fn(c) { @mod_swift.SwiftModule::from_config(c) }, schema: @mod_swift.SwiftModule::schema, description: "The currently installed version of Swift" },
  { name: "terraform", create: fn(c) { @mod_terraform.TerraformModule::from_config(c) }, schema: @mod_terraform.TerraformModule::schema, description: "The current Terraform workspace and version" },
  { name: "time", create: fn(c) { @mod_time.TimeModule::from_config(c) }, schema: @mod_time.TimeModule::schema, description: "The current local time" },
  { name: "typst", create: fn(c) { @mod_typst.TypstModule::from_config(c) }, schema: @mod_typst.TypstModule::schema, description: "The currently installed version of Typst" },
  { name: "username", create: fn(c) { @mod_username.UsernameModule::from_config(c) }, schema: @mod_username.UsernameModule::schema, description: "The current username" },
  { name: "vagrant", create: fn(c) { @mod_vagrant.VagrantModule::from_config(c) }, schema: @mod_vagrant.VagrantModule::schema, description: "The currently installed version of Vagrant" },
  { name: "vcsh", create: fn(c) { @mod_vcsh.VcshModule::from_config(c) }, schema: @mod_vcsh.VcshModule::schema, description: "The current VCSH repository" },
  { name: "vlang", create: fn(c) { @mod_vlang.VlangModule::from_config(c) }, schema: @mod_vlang.VlangModule::schema, description: "The currently installed version of V" },
  { name: "xmake", create: fn(c) { @mod_xmake.XmakeModule::from_config(c) }, schema: @mod_xmake.XmakeModule::schema, description: "The currently installed version of XMake" },
  { name: "zig", create: fn(c) { @mod_zig.ZigModule::from_config(c) }, schema: @mod_zig.ZigModule::schema, description: "The currently installed version of Zig" },
]

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  module_registry.iter().fold(
    init=(Map::new() : Map[String, &@ms.PromptModule]),
    fn(modules, entry) {
      modules[entry.name] = (entry.create)(config)
      modules
    },
  )
}

///|
fn collect_all_schemas() -> Array[@config.ModuleSchema] {
  module_registry.iter().map(fn(entry) { (entry.schema)() }).collect()
}
