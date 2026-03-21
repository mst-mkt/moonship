///|
pub struct MemoryUsageModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  threshold : Int
}

///|
pub fn MemoryUsageModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "memory_usage",
  ),
) -> MemoryUsageModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐏 "),
    threshold: config.get_int_prop("threshold", default=75),
  }
}

///|
pub fn MemoryUsageModule::from_config(
  config : @config.Config,
) -> MemoryUsageModule {
  MemoryUsageModule::new(config=config.get_module("memory_usage"))
}

///|
pub impl @ms.PromptModule for MemoryUsageModule with name(_self) -> String {
  "memory_usage"
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
