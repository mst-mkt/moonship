///|
pub struct HgStateModule {
  disabled : Bool
  format : String
  style : String
  merge : String
  rebase : String
  update : String
  bisect : String
  shelve : String
  graft : String
  transplant : String
  histedit : String
}

///|
pub fn HgStateModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "hg_state",
  ),
) -> HgStateModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    merge: config.get_prop("merge", default="MERGING"),
    rebase: config.get_prop("rebase", default="REBASING"),
    update: config.get_prop("update", default="UPDATING"),
    bisect: config.get_prop("bisect", default="BISECTING"),
    shelve: config.get_prop("shelve", default="SHELVING"),
    graft: config.get_prop("graft", default="GRAFTING"),
    transplant: config.get_prop("transplant", default="TRANSPLANTING"),
    histedit: config.get_prop("histedit", default="HISTEDITING"),
  }
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
  let state = self.detect_hg_state(hg_dir)
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
fn HgStateModule::detect_hg_state(
  self : HgStateModule,
  hg_dir : String,
) -> String {
  if @fs.path_exists(hg_dir + "/rebasestate") {
    return self.rebase
  }

  if @fs.path_exists(hg_dir + "/updatestate") {
    return self.update
  }

  if @fs.path_exists(hg_dir + "/bisect.state") {
    return self.bisect
  }

  if @fs.path_exists(hg_dir + "/graftstate") {
    return self.graft
  }

  if @fs.path_exists(hg_dir + "/transplant/journal") {
    return self.transplant
  }

  if @fs.path_exists(hg_dir + "/histedit-state") {
    return self.histedit
  }

  if is_merge_state(hg_dir) {
    return self.merge
  }

  ""
}

///|
fn is_merge_state(hg_dir : String) -> Bool {
  let dirstate_path = hg_dir + "/dirstate"

  let bytes = @fs.read_file_to_bytes(dirstate_path) catch { _ => return false }

  guard bytes.length() >= 40 else { return false }

  for i = 20; i < 40; i = i + 1 {
    if bytes[i] != 0 {
      return true
    }
  }

  false
}
