///|
pub struct CharacterModule {}

///|
pub fn CharacterModule::new() -> CharacterModule {
  CharacterModule::{  }
}

///|
pub impl @ms.PromptModule for CharacterModule with name(_self) -> String {
  "character"
}

///|
pub impl @ms.PromptModule for CharacterModule with execute(
  _self,
  ctx : @context.Context,
) -> @ms.ModuleOutput? {
  let config = ctx.config.get_module("character")
  guard not(config.disabled) else { return None }

  let symbol = if ctx.status == 0 {
    config.get_prop("success_symbol")
  } else {
    config.get_prop("error_symbol")
  }

  let vars : Map[String, String] = { "symbol": symbol }
  let segments = @ms.format_string(
    config.format,
    vars,
    @terminal.Style::default(),
  )

  Some(@ms.ModuleOutput::new(segments))
}
