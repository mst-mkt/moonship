///|
pub struct Segment {
  text : String
  style : @terminal.Style
  is_fill : Bool
}

///|
pub fn Segment::new(
  text : String,
  style? : @terminal.Style = @terminal.Style::default(),
  is_fill? : Bool = false,
) -> Segment {
  { text, style, is_fill }
}

///|
pub fn Segment::fill(
  symbol : String,
  style : @terminal.Style,
) -> Segment {
  { text: symbol, style, is_fill: true }
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
  .fold(init=(StringBuilder::new(), @terminal.Style::default()), fn(state, seg) {
    let (buf, prev) = state
    let resolved = seg.style.resolve_prev(prev)
    buf.write_string(@terminal.stylize(seg.text, resolved))
    (buf, resolved)
  })
  .0
  .to_string()
}

///|
pub fn ModuleOutput::render_with_fill(
  self : ModuleOutput,
  terminal_width : Int,
) -> String {
  let has_fill = self.segments.iter().any(fn(seg) { seg.is_fill })
  guard has_fill else { return self.render() }

  let non_fill_width = self.segments.iter().fold(init=0, fn(acc, seg) {
    if seg.is_fill { acc } else { acc + visible_width(seg.text) }
  })

  let fill_count = self.segments.iter().fold(init=0, fn(acc, seg) {
    if seg.is_fill { acc + 1 } else { acc }
  })

  let remaining = if terminal_width > non_fill_width {
    terminal_width - non_fill_width
  } else {
    0
  }
  let fill_width = remaining / fill_count

  self.segments
  .iter()
  .fold(init=(StringBuilder::new(), @terminal.Style::default()), fn(state, seg) {
    let (buf, prev) = state
    let resolved = seg.style.resolve_prev(prev)
    let text = if seg.is_fill {
      repeat_to_width(seg.text, fill_width)
    } else {
      seg.text
    }
    buf.write_string(@terminal.stylize(text, resolved))
    (buf, resolved)
  })
  .0
  .to_string()
}

///|
fn visible_width(s : String) -> Int {
  let len = s.length()

  loop (0, 0, false) {
    (i, width, in_escape) => {
      if i >= len {
        break width
      }

      let ch = s[i].unsafe_to_char()
      if in_escape {
        if ch == 'm' {
          continue (i + 1, width, false)
        } else {
          continue (i + 1, width, true)
        }
      } else if ch == '\u001b' {
        continue (i + 1, width, true)
      } else {
        continue (i + 1, width + 1, false)
      }
    }
  }
}

///|
fn repeat_to_width(symbol : String, width : Int) -> String {
  guard width > 0 && not(symbol.is_empty()) else { return "" }

  let sym_len = symbol.length()
  let buf = StringBuilder::new()

  for i = 0; i < width; i = i + 1 {
    buf.write_char(symbol[i % sym_len].unsafe_to_char())
  }

  buf.to_string()
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
  is_async(Self) -> Bool
  async execute(Self, @context.Context) -> ModuleResult
}
