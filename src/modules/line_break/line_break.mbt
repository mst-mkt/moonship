///|
pub struct LineBreakModule {
  disabled : Bool
}

///|
pub fn LineBreakModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "line_break",
  ),
) -> LineBreakModule {
  { disabled: config.disabled }
}

///|
pub fn LineBreakModule::from_config(config : @config.Config) -> LineBreakModule {
  LineBreakModule::new(config=config.get_module("line_break"))
}

///|
pub impl @ms.PromptModule for LineBreakModule with name(_self) -> String {
  "line_break"
}

///|
pub impl @ms.PromptModule for LineBreakModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  Output(@ms.ModuleOutput::new([@ms.Segment::new("\n")]))
}
