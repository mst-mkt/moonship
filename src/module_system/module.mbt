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
pub(open) trait PromptModule {
  name(Self) -> String
  execute(Self, @context.Context) -> ModuleOutput?
}
