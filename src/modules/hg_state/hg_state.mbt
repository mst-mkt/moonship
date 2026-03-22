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
pub fn HgStateModule::from_table(table : @config.ModuleTable) -> HgStateModule {
  let d = HgStateModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    merge: table.get_string("merge").unwrap_or(d.merge),
    rebase: table.get_string("rebase").unwrap_or(d.rebase),
    update: table.get_string("update").unwrap_or(d.update),
    bisect: table.get_string("bisect").unwrap_or(d.bisect),
    shelve: table.get_string("shelve").unwrap_or(d.shelve),
    graft: table.get_string("graft").unwrap_or(d.graft),
    transplant: table.get_string("transplant").unwrap_or(d.transplant),
    histedit: table.get_string("histedit").unwrap_or(d.histedit),
  }
}

///|
pub fn HgStateModule::from_config(config : @config.Config) -> HgStateModule {
  match config.get_raw_module("hg_state") {
    Some(table) => HgStateModule::from_table(table)
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

  loop 20 {
    i => {
      guard i < 40 else { break false }

      if bytes[i] != 0 {
        break true
      }
      continue i + 1
    }
  }
}

///|
pub fn HgStateModule::schema() -> @config.ModuleSchema {
  let d = HgStateModule::default()
  {
    name: "hg_state",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "merge", field_type: @config.FString, default_value: d.merge },
      { name: "rebase", field_type: @config.FString, default_value: d.rebase },
      { name: "update", field_type: @config.FString, default_value: d.update },
      { name: "bisect", field_type: @config.FString, default_value: d.bisect },
      { name: "shelve", field_type: @config.FString, default_value: d.shelve },
      { name: "graft", field_type: @config.FString, default_value: d.graft },
      {
        name: "transplant",
        field_type: @config.FString,
        default_value: d.transplant,
      },
      {
        name: "histedit",
        field_type: @config.FString,
        default_value: d.histedit,
      },
    ],
  }
}
