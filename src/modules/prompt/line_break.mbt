///|
pub struct LineBreakModule {
  disabled : Bool
  async_render : Bool
}

///|
pub fn LineBreakModule::default() -> LineBreakModule {
  { disabled: false, async_render: false }
}

///|
pub fn LineBreakModule::from_table(
  table : @config.ModuleTable,
) -> LineBreakModule {
  let d = LineBreakModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
  }
}

///|
pub fn LineBreakModule::from_config(config : @config.Config) -> LineBreakModule {
  match config.get_raw_module("line_break") {
    Some(table) => LineBreakModule::from_table(table)
    None => LineBreakModule::default()
  }
}

///|
pub impl @ms.PromptModule for LineBreakModule with name(_self) -> String {
  "line_break"
}

///|
pub impl @ms.PromptModule for LineBreakModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for LineBreakModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  Output(@ms.ModuleOutput::new([@ms.Segment::new("\n")]))
}

///|
pub fn LineBreakModule::schema() -> @config.ModuleSchema {
  let d = LineBreakModule::default()
  {
    name: "line_break",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
    ],
  }
}
