///|
pub struct BatteryModule {
  disabled : Bool
  format : String
  full_symbol : String
  charging_symbol : String
  discharging_symbol : String
  unknown_symbol : String
  empty_symbol : String
  display_threshold : Int
  display_style : String
}

///|
pub fn BatteryModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "battery",
  ),
) -> BatteryModule {
  {
    disabled: config.disabled,
    format: config.format,
    full_symbol: config.get_prop("full_symbol", default="󰁹 "),
    charging_symbol: config.get_prop("charging_symbol", default="󰂄 "),
    discharging_symbol: config.get_prop("discharging_symbol", default="󰂃 "),
    unknown_symbol: config.get_prop("unknown_symbol", default="󰂑 "),
    empty_symbol: config.get_prop("empty_symbol", default="󰂎 "),
    display_threshold: config.get_int_prop("display_threshold", default=10),
    display_style: config.get_prop("display_style", default="red bold"),
  }
}

///|
pub fn BatteryModule::from_config(config : @config.Config) -> BatteryModule {
  BatteryModule::new(config=config.get_module("battery"))
}

///|
pub impl @ms.PromptModule for BatteryModule with name(_self) -> String {
  "battery"
}

///|
pub impl @ms.PromptModule for BatteryModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for BatteryModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let (percentage, status) = read_battery()
  guard percentage >= 0 else { return Skipped("no battery found") }
  guard percentage <= self.display_threshold else {
    return Skipped("battery above display threshold")
  }

  let symbol = match status {
    "Charging" => self.charging_symbol
    "Full" => self.full_symbol
    "Not charging" => self.full_symbol
    "Discharging" =>
      if percentage <= 5 {
        self.empty_symbol
      } else {
        self.discharging_symbol
      }
    _ => self.unknown_symbol
  }

  let vars : Map[String, String] = {
    "percentage": percentage.to_string() + "%",
    "symbol": symbol,
    "style": self.display_style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn read_battery() -> (Int, String) {
  let bat_paths = [
    "/sys/class/power_supply/BAT0", "/sys/class/power_supply/BAT1",
  ]

  for path in bat_paths {
    let cap_str = @fs.read_file_to_string(path + "/capacity") catch {
      _ => continue
    }

    let status_str = @fs.read_file_to_string(path + "/status") catch {
      _ => continue
    }

    let cap_lines = cap_str.split("\n").collect()
    let cap = if cap_lines.length() > 0 {
      parse_battery_int(cap_lines[0].to_string())
    } else {
      -1
    }

    let status_lines = status_str.split("\n").collect()
    let status = if status_lines.length() > 0 {
      status_lines[0].to_string()
    } else {
      ""
    }

    return (cap, status)
  }

  (-1, "")
}

///|
fn parse_battery_int(s : String) -> Int {
  let mut result = 0

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      break
    }
  }

  result
}
