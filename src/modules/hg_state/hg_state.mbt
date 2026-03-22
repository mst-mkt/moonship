///|
pub struct HgStateModule {
  disabled : Bool
  async_render : Bool
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
pub fn HgStateModule::default() -> HgStateModule {
  {
    disabled: true,
    async_render: false,
    format: "\\([$state]($style)\\) ",
    style: "bold yellow",
    merge: "MERGING",
    rebase: "REBASING",
    update: "UPDATING",
    bisect: "BISECTING",
    shelve: "SHELVING",
    graft: "GRAFTING",
    transplant: "TRANSPLANTING",
    histedit: "HISTEDITING",
  }
}

///|
pub fn HgStateModule::from_toml_table(
  table : @config.ModuleTable,
) -> HgStateModule {
  let d = HgStateModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    merge: @config.get_toml_string(table, "merge").unwrap_or(d.merge),
    rebase: @config.get_toml_string(table, "rebase").unwrap_or(d.rebase),
    update: @config.get_toml_string(table, "update").unwrap_or(d.update),
    bisect: @config.get_toml_string(table, "bisect").unwrap_or(d.bisect),
    shelve: @config.get_toml_string(table, "shelve").unwrap_or(d.shelve),
    graft: @config.get_toml_string(table, "graft").unwrap_or(d.graft),
    transplant: @config.get_toml_string(table, "transplant").unwrap_or(
      d.transplant,
    ),
    histedit: @config.get_toml_string(table, "histedit").unwrap_or(d.histedit),
  }
}

///|
pub fn HgStateModule::from_config(config : @config.Config) -> HgStateModule {
  match config.get_raw_module("hg_state") {
    Some(table) => HgStateModule::from_toml_table(table)
    None => HgStateModule::default()
  }
}

///|
pub impl @ms.PromptModule for HgStateModule with name(_self) -> String {
  "hg_state"
}

///|
pub impl @ms.PromptModule for HgStateModule with is_async(self) -> Bool {
  self.async_render
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
