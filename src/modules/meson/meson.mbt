///|
pub struct MesonModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn MesonModule::default() -> MesonModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$project]($style) ",
    style: "blue bold",
    symbol: "⬢ ",
  }
}

///|
pub fn MesonModule::from_toml_table(table : @config.ModuleTable) -> MesonModule {
  let d = MesonModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn MesonModule::from_config(config : @config.Config) -> MesonModule {
  match config.get_raw_module("meson") {
    Some(table) => MesonModule::from_toml_table(table)
    None => MesonModule::default()
  }
}

///|
pub impl @ms.PromptModule for MesonModule with name(_self) -> String {
  "meson"
}

///|
pub impl @ms.PromptModule for MesonModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for MesonModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let devenv = @sys.get_env_var("MESON_DEVENV").unwrap_or("")
  guard devenv == "1" else { return Skipped("not in meson devenv") }

  let project_raw = @sys.get_env_var("MESON_PROJECT_NAME").unwrap_or("")
  let project = trim(project_raw)
  guard not(project.is_empty()) else { return Skipped("no meson project name") }

  let vars : Map[String, String] = {
    "project": project,
    "symbol": self.symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn trim(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  while start < end && s[start].unsafe_to_char() == ' ' {
    start += 1
  }

  while end > start && s[end - 1].unsafe_to_char() == ' ' {
    end -= 1
  }

  s[start:end].to_string()
}
