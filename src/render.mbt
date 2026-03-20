///|
let module_order : Array[String] = [
  "username", "hostname", "directory", "git_branch", "git_commit", "git_state", "git_status",
  "package", "bun", "c", "cmake", "cpp", "crystal", "dart", "deno", "dotnet", "elixir",
  "elm", "erlang", "fortran", "gleam", "golang", "gradle", "haskell", "haxe", "java",
  "julia", "kotlin", "lua", "maven", "moonbit", "nim", "nodejs", "ocaml", "perl",
  "php", "purescript", "python", "ruby", "rust", "scala", "swift", "terraform", "zig",
  "cmd_duration", "line_break", "jobs", "character",
]

///|
async fn render_prompt(ctx : @context.Context) -> String {
  let modules = build_modules(ctx.config)
  let format = expand_all(ctx.config.format, modules)
  let segment_vars : Map[String, Array[@ms.Segment]] = {}

  for name in @ms.extract_module_names(format) {
    guard modules.get(name) is Some(m) else { continue }
    guard m.execute(ctx) is Output(output) else { continue }
    segment_vars[name] = output.segments
  }

  @ms.compose_segments(format, segment_vars).render()
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
    .map(fn(name) { "$" + name })
    .collect()
    .join("")

  replace_var(format, "all", expansion)
}

///|
fn replace_var(s : String, var_name : String, replacement : String) -> String {
  let target = "$" + var_name
  let buf = StringBuilder::new()
  let len = s.length()
  let mut i = 0

  while i < len {
    let remaining = s[i:].to_string()
    if remaining.has_prefix(target) {
      let after = i + target.length()
      if after >= len || not(is_ident_char(s[after].unsafe_to_char())) {
        buf.write_string(replacement)
        i = after
        continue
      }
    }
    buf.write_char(s[i].unsafe_to_char())
    i += 1
  }

  buf.to_string()
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
  modules["nodejs"] = @mod_nodejs.NodejsModule::from_config(config)
  modules["python"] = @mod_python.PythonModule::from_config(config)
  modules["rust"] = @mod_rust.RustModule::from_config(config)
  modules["golang"] = @mod_golang.GolangModule::from_config(config)
  modules["java"] = @mod_java.JavaModule::from_config(config)
  modules["ruby"] = @mod_ruby.RubyModule::from_config(config)
  modules["deno"] = @mod_deno.DenoModule::from_config(config)
  modules["bun"] = @mod_bun.BunModule::from_config(config)
  modules["dart"] = @mod_dart.DartModule::from_config(config)
  modules["elixir"] = @mod_elixir.ElixirModule::from_config(config)
  modules["lua"] = @mod_lua.LuaModule::from_config(config)
  modules["perl"] = @mod_perl.PerlModule::from_config(config)
  modules["php"] = @mod_php.PhpModule::from_config(config)
  modules["kotlin"] = @mod_kotlin.KotlinModule::from_config(config)
  modules["swift"] = @mod_swift.SwiftModule::from_config(config)
  modules["scala"] = @mod_scala.ScalaModule::from_config(config)
  modules["zig"] = @mod_zig.ZigModule::from_config(config)
  modules["dotnet"] = @mod_dotnet.DotnetModule::from_config(config)
  modules["moonbit"] = @mod_moonbit.MoonbitModule::from_config(config)
  modules["julia"] = @mod_julia.JuliaModule::from_config(config)
  modules["nim"] = @mod_nim.NimModule::from_config(config)
  modules["gleam"] = @mod_gleam.GleamModule::from_config(config)
  modules["erlang"] = @mod_erlang.ErlangModule::from_config(config)
  modules["elm"] = @mod_elm.ElmModule::from_config(config)
  modules["haskell"] = @mod_haskell.HaskellModule::from_config(config)
  modules["c"] = @mod_c.CModule::from_config(config)
  modules["cpp"] = @mod_cpp.CppModule::from_config(config)
  modules["cmake"] = @mod_cmake.CMakeModule::from_config(config)
  modules["crystal"] = @mod_crystal.CrystalModule::from_config(config)
  modules["terraform"] = @mod_terraform.TerraformModule::from_config(config)
  modules["gradle"] = @mod_gradle.GradleModule::from_config(config)
  modules["maven"] = @mod_maven.MavenModule::from_config(config)
  modules["ocaml"] = @mod_ocaml.OCamlModule::from_config(config)
  modules["haxe"] = @mod_haxe.HaxeModule::from_config(config)
  modules["fortran"] = @mod_fortran.FortranModule::from_config(config)
  modules["purescript"] = @mod_purescript.PureScriptModule::from_config(config)
  modules["hostname"] = @mod_hostname.HostnameModule::from_config(config)
  modules["username"] = @mod_username.UsernameModule::from_config(config)
  modules
}
