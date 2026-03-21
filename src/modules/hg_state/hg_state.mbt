///|
pub struct HgStateModule {
  disabled : Bool
  format : String
  style : String
}

///|
pub fn HgStateModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "hg_state",
  ),
) -> HgStateModule {
  { disabled: config.disabled, format: config.format, style: config.style }
}

///|
pub fn HgStateModule::from_config(config : @config.Config) -> HgStateModule {
  HgStateModule::new(config=config.get_module("hg_state"))
}

///|
pub impl @ms.PromptModule for HgStateModule with name(_self) -> String {
  "hg_state"
}

///|
pub impl @ms.PromptModule for HgStateModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @fs.path_exists(ctx.cwd + "/.hg") else {
    return Skipped("not in hg repo")
  }

  let hg_dir = ctx.cwd + "/.hg"
  let state = detect_hg_state(hg_dir)
  guard not(state.is_empty()) else { return Skipped("no hg state") }

  let vars : Map[String, String] = { "state": state, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn detect_hg_state(hg_dir : String) -> String {
  if @fs.path_exists(hg_dir + "/rebasestate") {
    return "REBASING"
  }

  if @fs.path_exists(hg_dir + "/updatestate") {
    return "UPDATING"
  }

  if @fs.path_exists(hg_dir + "/bisect.state") {
    return "BISECTING"
  }

  if @fs.path_exists(hg_dir + "/graftstate") {
    return "GRAFTING"
  }

  if @fs.path_exists(hg_dir + "/transplant/journal") {
    return "TRANSPLANTING"
  }

  if @fs.path_exists(hg_dir + "/histedit-state") {
    return "HISTEDITING"
  }

  ""
}
