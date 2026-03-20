///|
pub struct Segment {
  text : String
  style : @terminal.Style
}

///|
pub fn Segment::new(
  text : String,
  style? : @terminal.Style = @terminal.Style::default(),
) -> Segment {
  { text, style }
}

///|
pub struct ModuleOutput {
  segments : Array[Segment]
}

///|
pub fn ModuleOutput::new(segments : Array[Segment]) -> ModuleOutput {
  { segments, }
}

///|
pub fn ModuleOutput::render(self : ModuleOutput) -> String {
  self.segments
  .iter()
  .map(fn(seg) { @terminal.stylize(seg.text, seg.style) })
  .collect()
  .join("")
}

///|
pub(all) enum ModuleResult {
  Output(ModuleOutput)
  Skipped(String)
  Disabled
}

///|
pub fn ModuleResult::output(self : ModuleResult) -> ModuleOutput? {
  match self {
    Output(o) => Some(o)
    _ => None
  }
}

///|
pub(open) trait PromptModule {
  name(Self) -> String
  async execute(Self, @context.Context) -> ModuleResult
}
