///|
pub(all) struct BatteryDisplayRule {
  threshold : Int
  style : String
  charging_symbol : String
  discharging_symbol : String
}

///|
pub struct BatteryModule {
  disabled : Bool
  async_render : Bool
  format : String
  full_symbol : String
  charging_symbol : String
  discharging_symbol : String
  unknown_symbol : String
  empty_symbol : String
  display : Array[BatteryDisplayRule]
}

///|
pub fn BatteryModule::default() -> BatteryModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol$percentage]($style) ",
    full_symbol: "󰁹 ",
    charging_symbol: "󰂄 ",
    discharging_symbol: "󰂃 ",
    unknown_symbol: "󰂑 ",
    empty_symbol: "󰂎 ",
    display: [
      {
        threshold: 10,
        style: "red bold",
        charging_symbol: "",
        discharging_symbol: "",
      },
    ],
  }
}

///|
pub fn BatteryModule::from_table(table : @config.ModuleTable) -> BatteryModule {
  let d = BatteryModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    full_symbol: table.get_string("full_symbol").unwrap_or(d.full_symbol),
    charging_symbol: table
    .get_string("charging_symbol")
    .unwrap_or(d.charging_symbol),
    discharging_symbol: table
    .get_string("discharging_symbol")
    .unwrap_or(d.discharging_symbol),
    unknown_symbol: table
    .get_string("unknown_symbol")
    .unwrap_or(d.unknown_symbol),
    empty_symbol: table.get_string("empty_symbol").unwrap_or(d.empty_symbol),
    display: parse_display_rules(table, d.display),
  }
}

///|
pub fn BatteryModule::from_config(config : @config.Config) -> BatteryModule {
  match config.get_raw_module("battery") {
    Some(table) => BatteryModule::from_table(table)
    None => BatteryModule::default()
  }
}

///|
pub impl @ms.PromptModule for BatteryModule with name(_self) -> String {
  "battery"
}

///|
pub impl @ms.PromptModule for BatteryModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for BatteryModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let (percentage, status) = read_battery()
  guard percentage >= 0 else { return Skipped("no battery found") }

  let rule = self.display.iter().find_first(fn(r) { percentage <= r.threshold })
  guard rule is Some(r) else {
    return Skipped("battery above all display thresholds")
  }

  let symbol = match status {
    "Charging" =>
      if r.charging_symbol.is_empty() {
        self.charging_symbol
      } else {
        r.charging_symbol
      }
    "Full" | "Not charging" => self.full_symbol
    "Empty" => self.empty_symbol
    "Discharging" =>
      if r.discharging_symbol.is_empty() {
        self.discharging_symbol
      } else {
        r.discharging_symbol
      }
    _ => self.unknown_symbol
  }

  let vars : Map[String, String] = {
    "percentage": "\{percentage}%",
    "symbol": symbol,
    "style": r.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_display_rules(
  table : @config.ModuleTable,
  defaults : Array[BatteryDisplayRule],
) -> Array[BatteryDisplayRule] {
  match table.0.get("display") {
    Some(@config.CArray(arr)) =>
      arr
      .iter()
      .filter_map(fn(item) {
        guard item is @config.CTable(rule_table) else { return None }

        let get_str = fn(key : String, default : String) -> String {
          match rule_table.get(key) {
            Some(@config.CString(s)) => s
            _ => default
          }
        }

        let get_int = fn(key : String, default : Int) -> Int {
          match rule_table.get(key) {
            Some(@config.CInt(n)) => n
            _ => default
          }
        }

        Some({
          threshold: get_int("threshold", 10),
          style: get_str("style", "red bold"),
          charging_symbol: get_str("charging_symbol", ""),
          discharging_symbol: get_str("discharging_symbol", ""),
        })
      })
      .collect()
    _ => defaults
  }
}

///|
fn read_battery() -> (Int, String) {
  let bat_paths = [
    "/sys/class/power_supply/BAT0", "/sys/class/power_supply/BAT1",
  ]

  loop 0 {
    i if i >= bat_paths.length() => break (-1, "")
    i => {
      let path = bat_paths[i]
      let cap_str = @fs.read_file_to_string(path + "/capacity") catch {
        _ => continue i + 1
      }

      let status_str = @fs.read_file_to_string(path + "/status") catch {
        _ => continue i + 1
      }

      let cap_lines = cap_str.split("\n").map(fn(s) { s.to_string() }).collect()
      let cap = if cap_lines.length() > 0 {
        @exec.parse_leading_int(cap_lines[0])
      } else {
        -1
      }

      let status_lines = status_str
        .split("\n")
        .map(fn(s) { s.to_string() })
        .collect()
      let status = if status_lines.length() > 0 { status_lines[0] } else { "" }

      break (cap, status)
    }
  }
}

///|
pub fn BatteryModule::schema() -> @config.ModuleSchema {
  let d = BatteryModule::default()
  {
    name: "battery",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      {
        name: "full_symbol",
        field_type: @config.FString,
        default_value: d.full_symbol,
      },
      {
        name: "charging_symbol",
        field_type: @config.FString,
        default_value: d.charging_symbol,
      },
      {
        name: "discharging_symbol",
        field_type: @config.FString,
        default_value: d.discharging_symbol,
      },
      {
        name: "unknown_symbol",
        field_type: @config.FString,
        default_value: d.unknown_symbol,
      },
      {
        name: "empty_symbol",
        field_type: @config.FString,
        default_value: d.empty_symbol,
      },
      {
        name: "display",
        field_type: @config.FString,
        default_value: "(array of display rules)",
      },
    ],
  }
}
