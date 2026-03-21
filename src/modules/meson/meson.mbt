///|
pub struct MesonModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn MesonModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("meson"),
) -> MesonModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⬢ "),
  }
}

///|
pub fn MesonModule::from_config(config : @config.Config) -> MesonModule {
  MesonModule::new(config=config.get_module("meson"))
}

///|
pub impl @ms.PromptModule for MesonModule with name(_self) -> String {
  "meson"
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
