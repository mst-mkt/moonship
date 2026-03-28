///|
struct ModuleEntry {
  name : String
  create : (@config.Config) -> &@ms.PromptModule
  schema : () -> @config.ModuleSchema
  description : String
}

///|
fn simple_lang_entry(
  defaults_fn : () -> @mod_lang.SimpleLangModule,
  description : String,
) -> ModuleEntry {
  let d = defaults_fn()
  {
    name: d.module_name,
    create: fn(c) { @mod_lang.SimpleLangModule::from_config(c, defaults_fn()) },
    schema: fn() { @mod_lang.SimpleLangModule::schema(defaults_fn()) },
    description,
  }
}

///|
let module_registry : Array[ModuleEntry] = [
  // Cloud modules
  {
    name: "aws",
    create: fn(c) { @mod_cloud.AwsModule::from_config(c) },
    schema: @mod_cloud.AwsModule::schema,
    description: "The current AWS region and profile",
  },
  {
    name: "azure",
    create: fn(c) { @mod_cloud.AzureModule::from_config(c) },
    schema: @mod_cloud.AzureModule::schema,
    description: "The current Azure subscription",
  },
  {
    name: "docker_context",
    create: fn(c) { @mod_cloud.DockerContextModule::from_config(c) },
    schema: @mod_cloud.DockerContextModule::schema,
    description: "The current Docker context",
  },
  {
    name: "gcloud",
    create: fn(c) { @mod_cloud.GcloudModule::from_config(c) },
    schema: @mod_cloud.GcloudModule::schema,
    description: "The current GCP project and region",
  },
  {
    name: "kubernetes",
    create: fn(c) { @mod_cloud.KubernetesModule::from_config(c) },
    schema: @mod_cloud.KubernetesModule::schema,
    description: "The current Kubernetes context and namespace",
  },
  {
    name: "nats",
    create: fn(c) { @mod_cloud.NatsModule::from_config(c) },
    schema: @mod_cloud.NatsModule::schema,
    description: "The current NATS context",
  },
  {
    name: "openstack",
    create: fn(c) { @mod_cloud.OpenstackModule::from_config(c) },
    schema: @mod_cloud.OpenstackModule::schema,
    description: "The current OpenStack cloud and project",
  },
  {
    name: "pulumi",
    create: fn(c) { @mod_cloud.PulumiModule::from_config(c) },
    schema: @mod_cloud.PulumiModule::schema,
    description: "The current Pulumi stack and version",
  },
  // Env modules
  {
    name: "conda",
    create: fn(c) { @mod_env.CondaModule::from_config(c) },
    schema: @mod_env.CondaModule::schema,
    description: "The current Conda environment",
  },
  {
    name: "direnv",
    create: fn(c) { @mod_env.DirenvModule::from_config(c) },
    schema: @mod_env.DirenvModule::schema,
    description: "The current direnv status",
  },
  {
    name: "env_var",
    create: fn(c) { @mod_env.EnvVarModule::from_config(c) },
    schema: @mod_env.EnvVarModule::schema,
    description: "A configured environment variable",
  },
  {
    name: "guix_shell",
    create: fn(c) { @mod_env.GuixShellModule::from_config(c) },
    schema: @mod_env.GuixShellModule::schema,
    description: "The current Guix shell environment",
  },
  {
    name: "meson",
    create: fn(c) { @mod_env.MesonModule::from_config(c) },
    schema: @mod_env.MesonModule::schema,
    description: "The current Meson dev environment",
  },
  {
    name: "mise",
    create: fn(c) { @mod_env.MiseModule::from_config(c) },
    schema: @mod_env.MiseModule::schema,
    description: "The current mise tool versions",
  },
  {
    name: "nix_shell",
    create: fn(c) { @mod_env.NixShellModule::from_config(c) },
    schema: @mod_env.NixShellModule::schema,
    description: "The current Nix shell environment",
  },
  {
    name: "pixi",
    create: fn(c) { @mod_env.PixiModule::from_config(c) },
    schema: @mod_env.PixiModule::schema,
    description: "The current Pixi environment",
  },
  {
    name: "spack",
    create: fn(c) { @mod_env.SpackModule::from_config(c) },
    schema: @mod_env.SpackModule::schema,
    description: "The current Spack environment",
  },
  // Prompt modules
  {
    name: "character",
    create: fn(c) { @mod_prompt.CharacterModule::from_config(c) },
    schema: @mod_prompt.CharacterModule::schema,
    description: "A character beside where the text is entered in your terminal",
  },
  {
    name: "cmd_duration",
    create: fn(c) { @mod_prompt.CmdDurationModule::from_config(c) },
    schema: @mod_prompt.CmdDurationModule::schema,
    description: "How long the last command took to execute",
  },
  {
    name: "custom",
    create: fn(c) { @mod_prompt.CustomModule::from_config(c) },
    schema: @mod_prompt.CustomModule::schema,
    description: "A custom module",
  },
  {
    name: "directory",
    create: fn(c) { @mod_prompt.DirectoryModule::from_config(c) },
    schema: @mod_prompt.DirectoryModule::schema,
    description: "The current working directory",
  },
  {
    name: "fill",
    create: fn(c) { @mod_prompt.FillModule::from_config(c) },
    schema: @mod_prompt.FillModule::schema,
    description: "Fill the remaining space on the line",
  },
  {
    name: "line_break",
    create: fn(c) { @mod_prompt.LineBreakModule::from_config(c) },
    schema: @mod_prompt.LineBreakModule::schema,
    description: "Separates the prompt into two lines",
  },
  {
    name: "package",
    create: fn(c) { @mod_prompt.PackageModule::from_config(c) },
    schema: @mod_prompt.PackageModule::schema,
    description: "The current package version",
  },
  {
    name: "status",
    create: fn(c) { @mod_prompt.StatusModule::from_config(c) },
    schema: @mod_prompt.StatusModule::schema,
    description: "The exit code of the last command",
  },
  // System modules
  {
    name: "battery",
    create: fn(c) { @mod_system.BatteryModule::from_config(c) },
    schema: @mod_system.BatteryModule::schema,
    description: "The current charge and status of the battery",
  },
  {
    name: "container",
    create: fn(c) { @mod_system.ContainerModule::from_config(c) },
    schema: @mod_system.ContainerModule::schema,
    description: "The current container indicator",
  },
  {
    name: "hostname",
    create: fn(c) { @mod_system.HostnameModule::from_config(c) },
    schema: @mod_system.HostnameModule::schema,
    description: "The current hostname",
  },
  {
    name: "jobs",
    create: fn(c) { @mod_system.JobsModule::from_config(c) },
    schema: @mod_system.JobsModule::schema,
    description: "The current number of background jobs",
  },
  {
    name: "localip",
    create: fn(c) { @mod_system.LocalipModule::from_config(c) },
    schema: @mod_system.LocalipModule::schema,
    description: "The current local IP address",
  },
  {
    name: "memory_usage",
    create: fn(c) { @mod_system.MemoryUsageModule::from_config(c) },
    schema: @mod_system.MemoryUsageModule::schema,
    description: "Current system memory and swap usage",
  },
  {
    name: "netns",
    create: fn(c) { @mod_system.NetnsModule::from_config(c) },
    schema: @mod_system.NetnsModule::schema,
    description: "The current network namespace",
  },
  {
    name: "os",
    create: fn(c) { @mod_system.OsModule::from_config(c) },
    schema: @mod_system.OsModule::schema,
    description: "The current operating system",
  },
  {
    name: "shell",
    create: fn(c) { @mod_system.ShellModule::from_config(c) },
    schema: @mod_system.ShellModule::schema,
    description: "The current shell indicator",
  },
  {
    name: "shlvl",
    create: fn(c) { @mod_system.ShlvlModule::from_config(c) },
    schema: @mod_system.ShlvlModule::schema,
    description: "The current shell level",
  },
  {
    name: "singularity",
    create: fn(c) { @mod_system.SingularityModule::from_config(c) },
    schema: @mod_system.SingularityModule::schema,
    description: "The current Singularity image",
  },
  {
    name: "sudo",
    create: fn(c) { @mod_system.SudoModule::from_config(c) },
    schema: @mod_system.SudoModule::schema,
    description: "The current sudo credentials status",
  },
  {
    name: "time",
    create: fn(c) { @mod_system.TimeModule::from_config(c) },
    schema: @mod_system.TimeModule::schema,
    description: "The current local time",
  },
  {
    name: "username",
    create: fn(c) { @mod_system.UsernameModule::from_config(c) },
    schema: @mod_system.UsernameModule::schema,
    description: "The current username",
  },
  // VCS modules
  {
    name: "fossil_branch",
    create: fn(c) { @mod_vcs.FossilBranchModule::from_config(c) },
    schema: @mod_vcs.FossilBranchModule::schema,
    description: "The current Fossil branch",
  },
  {
    name: "fossil_metrics",
    create: fn(c) { @mod_vcs.FossilMetricsModule::from_config(c) },
    schema: @mod_vcs.FossilMetricsModule::schema,
    description: "The current Fossil metrics",
  },
  {
    name: "git_branch",
    create: fn(c) { @mod_vcs.GitBranchModule::from_config(c) },
    schema: @mod_vcs.GitBranchModule::schema,
    description: "The current Git branch",
  },
  {
    name: "git_commit",
    create: fn(c) { @mod_vcs.GitCommitModule::from_config(c) },
    schema: @mod_vcs.GitCommitModule::schema,
    description: "The current Git commit hash",
  },
  {
    name: "git_metrics",
    create: fn(c) { @mod_vcs.GitMetricsModule::from_config(c) },
    schema: @mod_vcs.GitMetricsModule::schema,
    description: "The current Git added/deleted lines",
  },
  {
    name: "git_state",
    create: fn(c) { @mod_vcs.GitStateModule::from_config(c) },
    schema: @mod_vcs.GitStateModule::schema,
    description: "The current Git operation state",
  },
  {
    name: "git_status",
    create: fn(c) { @mod_vcs.GitStatusModule::from_config(c) },
    schema: @mod_vcs.GitStatusModule::schema,
    description: "Symbol representing the state of the repo",
  },
  {
    name: "hg_branch",
    create: fn(c) { @mod_vcs.HgBranchModule::from_config(c) },
    schema: @mod_vcs.HgBranchModule::schema,
    description: "The current Mercurial branch",
  },
  {
    name: "hg_state",
    create: fn(c) { @mod_vcs.HgStateModule::from_config(c) },
    schema: @mod_vcs.HgStateModule::schema,
    description: "The current Mercurial operation state",
  },
  {
    name: "pijul_channel",
    create: fn(c) { @mod_vcs.PijulChannelModule::from_config(c) },
    schema: @mod_vcs.PijulChannelModule::schema,
    description: "The current Pijul channel",
  },
  {
    name: "vcsh",
    create: fn(c) { @mod_vcs.VcshModule::from_config(c) },
    schema: @mod_vcs.VcshModule::schema,
    description: "The current VCSH repository",
  },
  // Complex lang modules (kept as separate types)
  {
    name: "c",
    create: fn(c) { @mod_lang.CModule::from_config(c) },
    schema: @mod_lang.CModule::schema,
    description: "The currently installed version of C compiler",
  },
  {
    name: "cpp",
    create: fn(c) { @mod_lang.CppModule::from_config(c) },
    schema: @mod_lang.CppModule::schema,
    description: "The currently installed version of C++ compiler",
  },
  {
    name: "daml",
    create: fn(c) { @mod_lang.DamlModule::from_config(c) },
    schema: @mod_lang.DamlModule::schema,
    description: "The currently installed version of DAML",
  },
  {
    name: "dotnet",
    create: fn(c) { @mod_lang.DotnetModule::from_config(c) },
    schema: @mod_lang.DotnetModule::schema,
    description: "The currently installed version of .NET",
  },
  {
    name: "elixir",
    create: fn(c) { @mod_lang.ElixirModule::from_config(c) },
    schema: @mod_lang.ElixirModule::schema,
    description: "The currently installed version of Elixir",
  },
  {
    name: "fortran",
    create: fn(c) { @mod_lang.FortranModule::from_config(c) },
    schema: @mod_lang.FortranModule::schema,
    description: "The currently installed version of Fortran",
  },
  {
    name: "golang",
    create: fn(c) { @mod_lang.GolangModule::from_config(c) },
    schema: @mod_lang.GolangModule::schema,
    description: "The currently installed version of Go",
  },
  {
    name: "gradle",
    create: fn(c) { @mod_lang.GradleModule::from_config(c) },
    schema: @mod_lang.GradleModule::schema,
    description: "The currently installed version of Gradle",
  },
  {
    name: "java",
    create: fn(c) { @mod_lang.JavaModule::from_config(c) },
    schema: @mod_lang.JavaModule::schema,
    description: "The currently installed version of Java",
  },
  {
    name: "kotlin",
    create: fn(c) { @mod_lang.KotlinModule::from_config(c) },
    schema: @mod_lang.KotlinModule::schema,
    description: "The currently installed version of Kotlin",
  },
  {
    name: "lua",
    create: fn(c) { @mod_lang.LuaModule::from_config(c) },
    schema: @mod_lang.LuaModule::schema,
    description: "The currently installed version of Lua",
  },
  {
    name: "maven",
    create: fn(c) { @mod_lang.MavenModule::from_config(c) },
    schema: @mod_lang.MavenModule::schema,
    description: "The currently installed version of Maven",
  },
  {
    name: "nodejs",
    create: fn(c) { @mod_lang.NodejsModule::from_config(c) },
    schema: @mod_lang.NodejsModule::schema,
    description: "The currently installed version of Node.js",
  },
  {
    name: "ocaml",
    create: fn(c) { @mod_lang.OCamlModule::from_config(c) },
    schema: @mod_lang.OCamlModule::schema,
    description: "The currently installed version of OCaml",
  },
  {
    name: "python",
    create: fn(c) { @mod_lang.PythonModule::from_config(c) },
    schema: @mod_lang.PythonModule::schema,
    description: "The currently installed version of Python",
  },
  {
    name: "raku",
    create: fn(c) { @mod_lang.RakuModule::from_config(c) },
    schema: @mod_lang.RakuModule::schema,
    description: "The currently installed version of Raku",
  },
  {
    name: "ruby",
    create: fn(c) { @mod_lang.RubyModule::from_config(c) },
    schema: @mod_lang.RubyModule::schema,
    description: "The currently installed version of Ruby",
  },
  {
    name: "scala",
    create: fn(c) { @mod_lang.ScalaModule::from_config(c) },
    schema: @mod_lang.ScalaModule::schema,
    description: "The currently installed version of Scala",
  },
  {
    name: "solidity",
    create: fn(c) { @mod_lang.SolidityModule::from_config(c) },
    schema: @mod_lang.SolidityModule::schema,
    description: "The currently installed version of Solidity",
  },
  {
    name: "terraform",
    create: fn(c) { @mod_lang.TerraformModule::from_config(c) },
    schema: @mod_lang.TerraformModule::schema,
    description: "The current Terraform workspace and version",
  },
  // Simple lang modules (data-driven via SimpleLangModule)
  simple_lang_entry(
    @mod_lang.buf_defaults, "The currently installed version of the Buf CLI",
  ),
  simple_lang_entry(
    @mod_lang.bun_defaults, "The currently installed version of Bun",
  ),
  simple_lang_entry(
    @mod_lang.cmake_defaults, "The currently installed version of CMake",
  ),
  simple_lang_entry(
    @mod_lang.cobol_defaults, "The currently installed version of COBOL",
  ),
  simple_lang_entry(
    @mod_lang.crystal_defaults, "The currently installed version of Crystal",
  ),
  simple_lang_entry(
    @mod_lang.dart_defaults, "The currently installed version of Dart",
  ),
  simple_lang_entry(
    @mod_lang.deno_defaults, "The currently installed version of Deno",
  ),
  simple_lang_entry(
    @mod_lang.elm_defaults, "The currently installed version of Elm",
  ),
  simple_lang_entry(
    @mod_lang.erlang_defaults, "The currently installed version of Erlang",
  ),
  simple_lang_entry(
    @mod_lang.fennel_defaults, "The currently installed version of Fennel",
  ),
  simple_lang_entry(
    @mod_lang.gleam_defaults, "The currently installed version of Gleam",
  ),
  simple_lang_entry(
    @mod_lang.haskell_defaults, "The currently installed version of Haskell",
  ),
  simple_lang_entry(
    @mod_lang.haxe_defaults, "The currently installed version of Haxe",
  ),
  simple_lang_entry(
    @mod_lang.helm_defaults, "The currently installed version of Helm",
  ),
  simple_lang_entry(
    @mod_lang.julia_defaults, "The currently installed version of Julia",
  ),
  simple_lang_entry(
    @mod_lang.mojo_defaults, "The currently installed version of Mojo",
  ),
  simple_lang_entry(
    @mod_lang.moonbit_defaults, "The currently installed version of MoonBit",
  ),
  simple_lang_entry(
    @mod_lang.nim_defaults, "The currently installed version of Nim",
  ),
  simple_lang_entry(
    @mod_lang.odin_defaults, "The currently installed version of Odin",
  ),
  simple_lang_entry(
    @mod_lang.opa_defaults, "The currently installed version of OPA",
  ),
  simple_lang_entry(
    @mod_lang.perl_defaults, "The currently installed version of Perl",
  ),
  simple_lang_entry(
    @mod_lang.php_defaults, "The currently installed version of PHP",
  ),
  simple_lang_entry(
    @mod_lang.purescript_defaults, "The currently installed version of PureScript",
  ),
  simple_lang_entry(
    @mod_lang.quarto_defaults, "The currently installed version of Quarto",
  ),
  simple_lang_entry(
    @mod_lang.red_defaults, "The currently installed version of Red",
  ),
  simple_lang_entry(
    @mod_lang.rlang_defaults, "The currently installed version of R",
  ),
  simple_lang_entry(
    @mod_lang.rust_defaults, "The currently installed version of Rust",
  ),
  simple_lang_entry(
    @mod_lang.swift_defaults, "The currently installed version of Swift",
  ),
  simple_lang_entry(
    @mod_lang.typst_defaults, "The currently installed version of Typst",
  ),
  simple_lang_entry(
    @mod_lang.vagrant_defaults, "The currently installed version of Vagrant",
  ),
  simple_lang_entry(
    @mod_lang.vlang_defaults, "The currently installed version of V",
  ),
  simple_lang_entry(
    @mod_lang.xmake_defaults, "The currently installed version of XMake",
  ),
  simple_lang_entry(
    @mod_lang.zig_defaults, "The currently installed version of Zig",
  ),
]

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}

  for entry in module_registry {
    modules[entry.name] = (entry.create)(config)
  }

  for child in config.get_child_module_names("env_var") {
    modules["env_var.\{child}"] = @mod_env.EnvVarModule::from_named_config(
      config, child,
    )
  }

  for child in config.get_child_module_names("custom") {
    modules["custom.\{child}"] = @mod_prompt.CustomModule::from_named_config(
      config, child,
    )
  }

  modules
}

///|
fn collect_all_schemas() -> Array[@config.ModuleSchema] {
  module_registry.iter().map(fn(entry) { (entry.schema)() }).collect()
}
