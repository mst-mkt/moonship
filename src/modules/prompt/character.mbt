///|
pub struct CharacterModule {
  disabled : Bool
  async_render : Bool
  format : String
  success_symbol : String
  error_symbol : String
  vimcmd_symbol : String
  vimcmd_visual_symbol : String
  vimcmd_replace_symbol : String
  vimcmd_replace_one_symbol : String
}

///|
pub fn CharacterModule::default() -> CharacterModule {
  {
    disabled: false,
    async_render: false,
    format: "$symbol ",
    success_symbol: "[❯](bold green)",
    error_symbol: "[❯](bold red)",
    vimcmd_symbol: "[❮](bold green)",
    vimcmd_visual_symbol: "[❮](bold yellow)",
    vimcmd_replace_symbol: "[❮](bold purple)",
    vimcmd_replace_one_symbol: "[❮](bold purple)",
  }
}

///|
pub fn CharacterModule::from_table(
  table : @config.ModuleTable,
) -> CharacterModule {
  let d = CharacterModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    success_symbol: table
    .get_string("success_symbol")
    .unwrap_or(d.success_symbol),
    error_symbol: table.get_string("error_symbol").unwrap_or(d.error_symbol),
    vimcmd_symbol: table.get_string("vimcmd_symbol").unwrap_or(d.vimcmd_symbol),
    vimcmd_visual_symbol: table
    .get_string("vimcmd_visual_symbol")
    .unwrap_or(d.vimcmd_visual_symbol),
    vimcmd_replace_symbol: table
    .get_string("vimcmd_replace_symbol")
    .unwrap_or(d.vimcmd_replace_symbol),
    vimcmd_replace_one_symbol: table
    .get_string("vimcmd_replace_one_symbol")
    .unwrap_or(d.vimcmd_replace_one_symbol),
  }
}

///|
pub fn CharacterModule::from_config(config : @config.Config) -> CharacterModule {
  match config.get_raw_module("character") {
    Some(table) => CharacterModule::from_table(table)
    None => CharacterModule::default()
  }
}

///|
pub impl @ms.PromptModule for CharacterModule with name(_self) -> String {
  "character"
}

///|
pub impl @ms.PromptModule for CharacterModule with is_async(self) -> Bool {
  self.async_render
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

///|
pub fn CharacterModule::schema() -> @config.ModuleSchema {
  let d = CharacterModule::default()
  {
    name: "character",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      {
        name: "success_symbol",
        field_type: @config.FString,
        default_value: d.success_symbol,
      },
      {
        name: "error_symbol",
        field_type: @config.FString,
        default_value: d.error_symbol,
      },
      {
        name: "vimcmd_symbol",
        field_type: @config.FString,
        default_value: d.vimcmd_symbol,
      },
      {
        name: "vimcmd_visual_symbol",
        field_type: @config.FString,
        default_value: d.vimcmd_visual_symbol,
      },
      {
        name: "vimcmd_replace_symbol",
        field_type: @config.FString,
        default_value: d.vimcmd_replace_symbol,
      },
      {
        name: "vimcmd_replace_one_symbol",
        field_type: @config.FString,
        default_value: d.vimcmd_replace_one_symbol,
      },
    ],
  }
}
