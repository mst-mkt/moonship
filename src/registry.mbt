///|
struct ModuleEntry {
  name : String
  create : (@config.Config) -> &@ms.PromptModule
  schema : () -> @config.ModuleSchema
  description : String
}

///|
let module_registry : Array[ModuleEntry] = [
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
    name: "battery",
    create: fn(c) { @mod_system.BatteryModule::from_config(c) },
    schema: @mod_system.BatteryModule::schema,
    description: "The current charge and status of the battery",
  },
  {
    name: "buf",
    create: fn(c) { @mod_lang.BufModule::from_config(c) },
    schema: @mod_lang.BufModule::schema,
    description: "The currently installed version of the Buf CLI",
  },
  {
    name: "bun",
    create: fn(c) { @mod_lang.BunModule::from_config(c) },
    schema: @mod_lang.BunModule::schema,
    description: "The currently installed version of Bun",
  },
  {
    name: "c",
    create: fn(c) { @mod_lang.CModule::from_config(c) },
    schema: @mod_lang.CModule::schema,
    description: "The currently installed version of C compiler",
  },
  {
    name: "character",
    create: fn(c) { @mod_prompt.CharacterModule::from_config(c) },
    schema: @mod_prompt.CharacterModule::schema,
    description: "A character beside where the text is entered in your terminal",
  },
  {
    name: "cmake",
    create: fn(c) { @mod_lang.CMakeModule::from_config(c) },
    schema: @mod_lang.CMakeModule::schema,
    description: "The currently installed version of CMake",
  },
  {
    name: "cmd_duration",
    create: fn(c) { @mod_prompt.CmdDurationModule::from_config(c) },
    schema: @mod_prompt.CmdDurationModule::schema,
    description: "How long the last command took to execute",
  },
  {
    name: "cobol",
    create: fn(c) { @mod_lang.CobolModule::from_config(c) },
    schema: @mod_lang.CobolModule::schema,
    description: "The currently installed version of COBOL",
  },
  {
    name: "conda",
    create: fn(c) { @mod_env.CondaModule::from_config(c) },
    schema: @mod_env.CondaModule::schema,
    description: "The current Conda environment",
  },
  {
    name: "container",
    create: fn(c) { @mod_system.ContainerModule::from_config(c) },
    schema: @mod_system.ContainerModule::schema,
    description: "The current container indicator",
  },
  {
    name: "cpp",
    create: fn(c) { @mod_lang.CppModule::from_config(c) },
    schema: @mod_lang.CppModule::schema,
    description: "The currently installed version of C++ compiler",
  },
  {
    name: "crystal",
    create: fn(c) { @mod_lang.CrystalModule::from_config(c) },
    schema: @mod_lang.CrystalModule::schema,
    description: "The currently installed version of Crystal",
  },
  {
    name: "custom",
    create: fn(c) { @mod_prompt.CustomModule::from_config(c) },
    schema: @mod_prompt.CustomModule::schema,
    description: "A custom module",
  },
  {
    name: "daml",
    create: fn(c) { @mod_lang.DamlModule::from_config(c) },
    schema: @mod_lang.DamlModule::schema,
    description: "The currently installed version of DAML",
  },
  {
    name: "dart",
    create: fn(c) { @mod_lang.DartModule::from_config(c) },
    schema: @mod_lang.DartModule::schema,
    description: "The currently installed version of Dart",
  },
  {
    name: "deno",
    create: fn(c) { @mod_lang.DenoModule::from_config(c) },
    schema: @mod_lang.DenoModule::schema,
    description: "The currently installed version of Deno",
  },
  {
    name: "directory",
    create: fn(c) { @mod_prompt.DirectoryModule::from_config(c) },
    schema: @mod_prompt.DirectoryModule::schema,
    description: "The current working directory",
  },
  {
    name: "direnv",
    create: fn(c) { @mod_env.DirenvModule::from_config(c) },
    schema: @mod_env.DirenvModule::schema,
    description: "The current direnv status",
  },
  {
    name: "docker_context",
    create: fn(c) { @mod_cloud.DockerContextModule::from_config(c) },
    schema: @mod_cloud.DockerContextModule::schema,
    description: "The current Docker context",
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
    name: "elm",
    create: fn(c) { @mod_lang.ElmModule::from_config(c) },
    schema: @mod_lang.ElmModule::schema,
    description: "The currently installed version of Elm",
  },
  {
    name: "env_var",
    create: fn(c) { @mod_env.EnvVarModule::from_config(c) },
    schema: @mod_env.EnvVarModule::schema,
    description: "A configured environment variable",
  },
  {
    name: "erlang",
    create: fn(c) { @mod_lang.ErlangModule::from_config(c) },
    schema: @mod_lang.ErlangModule::schema,
    description: "The currently installed version of Erlang",
  },
  {
    name: "fennel",
    create: fn(c) { @mod_lang.FennelModule::from_config(c) },
    schema: @mod_lang.FennelModule::schema,
    description: "The currently installed version of Fennel",
  },
  {
    name: "fill",
    create: fn(c) { @mod_prompt.FillModule::from_config(c) },
    schema: @mod_prompt.FillModule::schema,
    description: "Fill the remaining space on the line",
  },
  {
    name: "fortran",
    create: fn(c) { @mod_lang.FortranModule::from_config(c) },
    schema: @mod_lang.FortranModule::schema,
    description: "The currently installed version of Fortran",
  },
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
    name: "gcloud",
    create: fn(c) { @mod_cloud.GcloudModule::from_config(c) },
    schema: @mod_cloud.GcloudModule::schema,
    description: "The current GCP project and region",
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
    name: "gleam",
    create: fn(c) { @mod_lang.GleamModule::from_config(c) },
    schema: @mod_lang.GleamModule::schema,
    description: "The currently installed version of Gleam",
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
    name: "guix_shell",
    create: fn(c) { @mod_env.GuixShellModule::from_config(c) },
    schema: @mod_env.GuixShellModule::schema,
    description: "The current Guix shell environment",
  },
  {
    name: "haskell",
    create: fn(c) { @mod_lang.HaskellModule::from_config(c) },
    schema: @mod_lang.HaskellModule::schema,
    description: "The currently installed version of Haskell",
  },
  {
    name: "haxe",
    create: fn(c) { @mod_lang.HaxeModule::from_config(c) },
    schema: @mod_lang.HaxeModule::schema,
    description: "The currently installed version of Haxe",
  },
  {
    name: "helm",
    create: fn(c) { @mod_lang.HelmModule::from_config(c) },
    schema: @mod_lang.HelmModule::schema,
    description: "The currently installed version of Helm",
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
    name: "hostname",
    create: fn(c) { @mod_system.HostnameModule::from_config(c) },
    schema: @mod_system.HostnameModule::schema,
    description: "The current hostname",
  },
  {
    name: "java",
    create: fn(c) { @mod_lang.JavaModule::from_config(c) },
    schema: @mod_lang.JavaModule::schema,
    description: "The currently installed version of Java",
  },
  {
    name: "jobs",
    create: fn(c) { @mod_system.JobsModule::from_config(c) },
    schema: @mod_system.JobsModule::schema,
    description: "The current number of background jobs",
  },
  {
    name: "julia",
    create: fn(c) { @mod_lang.JuliaModule::from_config(c) },
    schema: @mod_lang.JuliaModule::schema,
    description: "The currently installed version of Julia",
  },
  {
    name: "kotlin",
    create: fn(c) { @mod_lang.KotlinModule::from_config(c) },
    schema: @mod_lang.KotlinModule::schema,
    description: "The currently installed version of Kotlin",
  },
  {
    name: "kubernetes",
    create: fn(c) { @mod_cloud.KubernetesModule::from_config(c) },
    schema: @mod_cloud.KubernetesModule::schema,
    description: "The current Kubernetes context and namespace",
  },
  {
    name: "line_break",
    create: fn(c) { @mod_prompt.LineBreakModule::from_config(c) },
    schema: @mod_prompt.LineBreakModule::schema,
    description: "Separates the prompt into two lines",
  },
  {
    name: "localip",
    create: fn(c) { @mod_system.LocalipModule::from_config(c) },
    schema: @mod_system.LocalipModule::schema,
    description: "The current local IP address",
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
    name: "memory_usage",
    create: fn(c) { @mod_system.MemoryUsageModule::from_config(c) },
    schema: @mod_system.MemoryUsageModule::schema,
    description: "Current system memory and swap usage",
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
    name: "mojo",
    create: fn(c) { @mod_lang.MojoModule::from_config(c) },
    schema: @mod_lang.MojoModule::schema,
    description: "The currently installed version of Mojo",
  },
  {
    name: "moonbit",
    create: fn(c) { @mod_lang.MoonbitModule::from_config(c) },
    schema: @mod_lang.MoonbitModule::schema,
    description: "The currently installed version of MoonBit",
  },
  {
    name: "nats",
    create: fn(c) { @mod_cloud.NatsModule::from_config(c) },
    schema: @mod_cloud.NatsModule::schema,
    description: "The current NATS context",
  },
  {
    name: "netns",
    create: fn(c) { @mod_system.NetnsModule::from_config(c) },
    schema: @mod_system.NetnsModule::schema,
    description: "The current network namespace",
  },
  {
    name: "nim",
    create: fn(c) { @mod_lang.NimModule::from_config(c) },
    schema: @mod_lang.NimModule::schema,
    description: "The currently installed version of Nim",
  },
  {
    name: "nix_shell",
    create: fn(c) { @mod_env.NixShellModule::from_config(c) },
    schema: @mod_env.NixShellModule::schema,
    description: "The current Nix shell environment",
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
    name: "odin",
    create: fn(c) { @mod_lang.OdinModule::from_config(c) },
    schema: @mod_lang.OdinModule::schema,
    description: "The currently installed version of Odin",
  },
  {
    name: "opa",
    create: fn(c) { @mod_lang.OpaModule::from_config(c) },
    schema: @mod_lang.OpaModule::schema,
    description: "The currently installed version of OPA",
  },
  {
    name: "openstack",
    create: fn(c) { @mod_cloud.OpenstackModule::from_config(c) },
    schema: @mod_cloud.OpenstackModule::schema,
    description: "The current OpenStack cloud and project",
  },
  {
    name: "os",
    create: fn(c) { @mod_system.OsModule::from_config(c) },
    schema: @mod_system.OsModule::schema,
    description: "The current operating system",
  },
  {
    name: "package",
    create: fn(c) { @mod_prompt.PackageModule::from_config(c) },
    schema: @mod_prompt.PackageModule::schema,
    description: "The current package version",
  },
  {
    name: "perl",
    create: fn(c) { @mod_lang.PerlModule::from_config(c) },
    schema: @mod_lang.PerlModule::schema,
    description: "The currently installed version of Perl",
  },
  {
    name: "php",
    create: fn(c) { @mod_lang.PhpModule::from_config(c) },
    schema: @mod_lang.PhpModule::schema,
    description: "The currently installed version of PHP",
  },
  {
    name: "pijul_channel",
    create: fn(c) { @mod_vcs.PijulChannelModule::from_config(c) },
    schema: @mod_vcs.PijulChannelModule::schema,
    description: "The current Pijul channel",
  },
  {
    name: "pixi",
    create: fn(c) { @mod_env.PixiModule::from_config(c) },
    schema: @mod_env.PixiModule::schema,
    description: "The current Pixi environment",
  },
  {
    name: "pulumi",
    create: fn(c) { @mod_cloud.PulumiModule::from_config(c) },
    schema: @mod_cloud.PulumiModule::schema,
    description: "The current Pulumi stack and version",
  },
  {
    name: "purescript",
    create: fn(c) { @mod_lang.PureScriptModule::from_config(c) },
    schema: @mod_lang.PureScriptModule::schema,
    description: "The currently installed version of PureScript",
  },
  {
    name: "python",
    create: fn(c) { @mod_lang.PythonModule::from_config(c) },
    schema: @mod_lang.PythonModule::schema,
    description: "The currently installed version of Python",
  },
  {
    name: "quarto",
    create: fn(c) { @mod_lang.QuartoModule::from_config(c) },
    schema: @mod_lang.QuartoModule::schema,
    description: "The currently installed version of Quarto",
  },
  {
    name: "raku",
    create: fn(c) { @mod_lang.RakuModule::from_config(c) },
    schema: @mod_lang.RakuModule::schema,
    description: "The currently installed version of Raku",
  },
  {
    name: "red",
    create: fn(c) { @mod_lang.RedModule::from_config(c) },
    schema: @mod_lang.RedModule::schema,
    description: "The currently installed version of Red",
  },
  {
    name: "rlang",
    create: fn(c) { @mod_lang.RlangModule::from_config(c) },
    schema: @mod_lang.RlangModule::schema,
    description: "The currently installed version of R",
  },
  {
    name: "ruby",
    create: fn(c) { @mod_lang.RubyModule::from_config(c) },
    schema: @mod_lang.RubyModule::schema,
    description: "The currently installed version of Ruby",
  },
  {
    name: "rust",
    create: fn(c) { @mod_lang.RustModule::from_config(c) },
    schema: @mod_lang.RustModule::schema,
    description: "The currently installed version of Rust",
  },
  {
    name: "scala",
    create: fn(c) { @mod_lang.ScalaModule::from_config(c) },
    schema: @mod_lang.ScalaModule::schema,
    description: "The currently installed version of Scala",
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
    name: "solidity",
    create: fn(c) { @mod_lang.SolidityModule::from_config(c) },
    schema: @mod_lang.SolidityModule::schema,
    description: "The currently installed version of Solidity",
  },
  {
    name: "spack",
    create: fn(c) { @mod_env.SpackModule::from_config(c) },
    schema: @mod_env.SpackModule::schema,
    description: "The current Spack environment",
  },
  {
    name: "status",
    create: fn(c) { @mod_prompt.StatusModule::from_config(c) },
    schema: @mod_prompt.StatusModule::schema,
    description: "The exit code of the last command",
  },
  {
    name: "sudo",
    create: fn(c) { @mod_system.SudoModule::from_config(c) },
    schema: @mod_system.SudoModule::schema,
    description: "The current sudo credentials status",
  },
  {
    name: "swift",
    create: fn(c) { @mod_lang.SwiftModule::from_config(c) },
    schema: @mod_lang.SwiftModule::schema,
    description: "The currently installed version of Swift",
  },
  {
    name: "terraform",
    create: fn(c) { @mod_lang.TerraformModule::from_config(c) },
    schema: @mod_lang.TerraformModule::schema,
    description: "The current Terraform workspace and version",
  },
  {
    name: "time",
    create: fn(c) { @mod_system.TimeModule::from_config(c) },
    schema: @mod_system.TimeModule::schema,
    description: "The current local time",
  },
  {
    name: "typst",
    create: fn(c) { @mod_lang.TypstModule::from_config(c) },
    schema: @mod_lang.TypstModule::schema,
    description: "The currently installed version of Typst",
  },
  {
    name: "username",
    create: fn(c) { @mod_system.UsernameModule::from_config(c) },
    schema: @mod_system.UsernameModule::schema,
    description: "The current username",
  },
  {
    name: "vagrant",
    create: fn(c) { @mod_lang.VagrantModule::from_config(c) },
    schema: @mod_lang.VagrantModule::schema,
    description: "The currently installed version of Vagrant",
  },
  {
    name: "vcsh",
    create: fn(c) { @mod_vcs.VcshModule::from_config(c) },
    schema: @mod_vcs.VcshModule::schema,
    description: "The current VCSH repository",
  },
  {
    name: "vlang",
    create: fn(c) { @mod_lang.VlangModule::from_config(c) },
    schema: @mod_lang.VlangModule::schema,
    description: "The currently installed version of V",
  },
  {
    name: "xmake",
    create: fn(c) { @mod_lang.XmakeModule::from_config(c) },
    schema: @mod_lang.XmakeModule::schema,
    description: "The currently installed version of XMake",
  },
  {
    name: "zig",
    create: fn(c) { @mod_lang.ZigModule::from_config(c) },
    schema: @mod_lang.ZigModule::schema,
    description: "The currently installed version of Zig",
  },
]

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  module_registry
  .iter()
  .fold(init=(Map::new() : Map[String, &@ms.PromptModule]), fn(modules, entry) {
    modules[entry.name] = (entry.create)(config)
    modules
  })
}

///|
fn collect_all_schemas() -> Array[@config.ModuleSchema] {
  module_registry.iter().map(fn(entry) { (entry.schema)() }).collect()
}
