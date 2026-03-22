///|
pub struct CharacterModule {
  disabled : Bool
  format : String
  success_symbol : String
  error_symbol : String
  vimcmd_symbol : String
  vimcmd_visual_symbol : String
  vimcmd_replace_symbol : String
  vimcmd_replace_one_symbol : String
}

///|
pub fn CharacterModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "character",
  ),
) -> CharacterModule {
  {
    disabled: config.disabled,
    format: config.format,
    success_symbol: config.get_prop("success_symbol"),
    error_symbol: config.get_prop("error_symbol"),
    vimcmd_symbol: config.get_prop("vimcmd_symbol", default="[❮](bold green)"),
    vimcmd_visual_symbol: config.get_prop(
      "vimcmd_visual_symbol",
      default="[❮](bold yellow)",
    ),
    vimcmd_replace_symbol: config.get_prop(
      "vimcmd_replace_symbol",
      default="[❮](bold purple)",
    ),
    vimcmd_replace_one_symbol: config.get_prop(
      "vimcmd_replace_one_symbol",
      default="[❮](bold purple)",
    ),
  }
}

///|
pub fn CharacterModule::from_config(config : @config.Config) -> CharacterModule {
  CharacterModule::new(config=config.get_module("character"))
}

///|
pub impl @ms.PromptModule for CharacterModule with name(_self) -> String {
  "character"
}

///|
pub impl @ms.PromptModule for CharacterModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for CharacterModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let symbol = match ctx.keymap {
    "vicmd" => self.vimcmd_symbol
    "visual" => self.vimcmd_visual_symbol
    "replace" => self.vimcmd_replace_symbol
    "replace_one" => self.vimcmd_replace_one_symbol
    _ => if ctx.status == 0 { self.success_symbol } else { self.error_symbol }
  }

  let vars : Map[String, String] = { "symbol": symbol }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
