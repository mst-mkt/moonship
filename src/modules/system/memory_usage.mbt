///|
pub struct MemoryUsageModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  threshold : Int
}

///|
pub fn MemoryUsageModule::default() -> MemoryUsageModule {
  {
    disabled: true,
    async_render: false,
    format: "via $symbol[$ram( | $swap)]($style) ",
    style: "white bold dimmed",
    symbol: "🐏 ",
    threshold: 75,
  }
}

///|
pub fn MemoryUsageModule::from_table(
  table : @config.ModuleTable,
) -> MemoryUsageModule {
  let d = MemoryUsageModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    threshold: table.get_int("threshold").unwrap_or(d.threshold),
  }
}

///|
pub fn MemoryUsageModule::from_config(
  config : @config.Config,
) -> MemoryUsageModule {
  match config.get_raw_module("memory_usage") {
    Some(table) => MemoryUsageModule::from_table(table)
    None => MemoryUsageModule::default()
  }
}

///|
pub impl @ms.PromptModule for MemoryUsageModule with name(_self) -> String {
  "memory_usage"
}

///|
pub impl @ms.PromptModule for MemoryUsageModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for MemoryUsageModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let content = @fs.read_file_to_string("/proc/meminfo") catch {
    _ => return Skipped("could not read /proc/meminfo")
  }

  let (total, available) = parse_meminfo(content)
  guard total > 0L else { return Skipped("invalid memory info") }

  let used = total - available
  let pct = (used * 100L / total).to_int()
  guard pct >= self.threshold else {
    return Skipped("memory usage below threshold")
  }

  let ram_str = "\{format_bytes(used)}/\{format_bytes(total)}"
  let ram_pct = "\{pct}%"
  let vars : Map[String, String] = {
    "ram": ram_str,
    "ram_pct": ram_pct,
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
fn parse_meminfo(content : String) -> (Int64, Int64) {
  let (total, available) = content
    .split("\n")
    .fold(init=(0L, 0L), fn(acc, line) {
      let s = line.to_string()

      if s.has_prefix("MemTotal:") {
        (parse_kb_value(s), acc.1)
      } else if s.has_prefix("MemAvailable:") {
        (acc.0, parse_kb_value(s))
      } else {
        acc
      }
    })

  (total * 1024L, available * 1024L)
}

///|
fn parse_kb_value(line : String) -> Int64 {
  @exec.split_to_strings(line, " ")
  .iter()
  .find_first(fn(s) {
    not(s.is_empty()) &&
    s.iter().nth(0).map(fn(c) { c >= '0' && c <= '9' }).unwrap_or(false)
  })
  .map(fn(s) {
    s
    .iter()
    .fold(init=(0L, true), fn(acc, c) {
      let (val, active) = acc
      if active && c >= '0' && c <= '9' {
        (val * 10L + (c.to_int() - '0'.to_int()).to_int64(), true)
      } else {
        (val, false)
      }
    }).0
  })
  .unwrap_or(0L)
}

///|
fn format_bytes(bytes : Int64) -> String {
  let gib = 1073741824L
  let mib = 1048576L

  if bytes >= gib {
    let whole = bytes / gib
    let frac = (bytes % gib * 10L / gib).to_int()
    "\{whole}.\{frac}GiB"
  } else {
    let whole = bytes / mib
    "\{whole}MiB"
  }
}

///|
pub fn MemoryUsageModule::schema() -> @config.ModuleSchema {
  let d = MemoryUsageModule::default()
  {
    name: "memory_usage",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "threshold",
        field_type: @config.FInt,
        default_value: d.threshold.to_string(),
      },
    ],
  }
}
