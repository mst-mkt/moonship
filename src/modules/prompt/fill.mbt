///|
pub struct FillModule {
  disabled : Bool
  symbol : String
  style : String
}

///|
pub fn FillModule::default() -> FillModule {
  { disabled: false, symbol: ".", style: "bold black" }
}

///|
pub fn FillModule::from_table(table : @config.ModuleTable) -> FillModule {
  let d = FillModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    style: table.get_string("style").unwrap_or(d.style),
  }
}

///|
pub fn FillModule::from_config(config : @config.Config) -> FillModule {
  match config.get_raw_module("fill") {
    Some(table) => FillModule::from_table(table)
    None => FillModule::default()
  }
}

///|
pub impl @ms.PromptModule for FillModule with name(_self) -> String {
  "fill"
}

///|
pub impl @ms.PromptModule for FillModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for FillModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let style = @terminal.parse_style(self.style)
  let segment = @ms.Segment::fill(self.symbol, style)

  Output(@ms.ModuleOutput::new([segment]))
}

///|
pub fn FillModule::schema() -> @config.ModuleSchema {
  let d = FillModule::default()
  {
    name: "fill",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      { name: "style", field_type: @config.FString, default_value: d.style },
    ],
  }
}
