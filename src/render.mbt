///|
fn render_prompt(ctx : @context.Context) -> String {
  let modules = build_modules(ctx.config)
  let segment_vars : Map[String, Array[@ms.Segment]] = {}

  for name in @ms.extract_module_names(ctx.config.format) {
    guard modules.get(name) is Some(m) else { continue }
    guard m.execute(ctx) is Output(output) else { continue }
    segment_vars[name] = output.segments
  }

  @ms.compose_segments(ctx.config.format, segment_vars).render()
}

///|
fn build_modules(config : @config.Config) -> Map[String, &@ms.PromptModule] {
  let modules : Map[String, &@ms.PromptModule] = {}
  modules["character"] = @mod_character.CharacterModule::from_config(config)
  modules["directory"] = @mod_directory.DirectoryModule::from_config(config)
  modules["git_branch"] = @mod_git_branch.GitBranchModule::from_config(config)
  modules["git_status"] = @mod_git_status.GitStatusModule::from_config(config)
  modules
}
