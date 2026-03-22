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
pub fn MemoryUsageModule::from_toml_table(
  table : @config.ModuleTable,
) -> MemoryUsageModule {
  let d = MemoryUsageModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    threshold: @config.get_toml_int(table, "threshold").unwrap_or(d.threshold),
  }
}

///|
pub fn MemoryUsageModule::from_config(
  config : @config.Config,
) -> MemoryUsageModule {
  match config.get_raw_module("memory_usage") {
    Some(table) => MemoryUsageModule::from_toml_table(table)
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

  let ram_str = format_bytes(used) + "/" + format_bytes(total)
  let ram_pct = pct.to_string() + "%"
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
  let lines = content.split("\n").collect()
  let mut total = 0L
  let mut available = 0L

  for line in lines {
    let s = line.to_string()
    if s.has_prefix("MemTotal:") {
      total = parse_kb_value(s)
    } else if s.has_prefix("MemAvailable:") {
      available = parse_kb_value(s)
    }
  }

  (total * 1024L, available * 1024L)
}

///|
fn parse_kb_value(line : String) -> Int64 {
  let parts = line.split(" ").collect()
  let mut val = 0L

  for part in parts {
    let s = part.to_string()
    if not(s.is_empty()) &&
      s[0].unsafe_to_char() >= '0' &&
      s[0].unsafe_to_char() <= '9' {
      for i = 0; i < s.length(); i = i + 1 {
        let c = s[i].unsafe_to_char()
        if c >= '0' && c <= '9' {
          val = val * 10L + (c.to_int() - '0'.to_int()).to_int64()
        }
      }
      break
    }
  }

  val
}

///|
fn format_bytes(bytes : Int64) -> String {
  let gib = 1073741824L
  let mib = 1048576L

  if bytes >= gib {
    let whole = bytes / gib
    let frac = (bytes % gib * 10L / gib).to_int()
    whole.to_string() + "." + frac.to_string() + "GiB"
  } else {
    let whole = bytes / mib
    whole.to_string() + "MiB"
  }
}
