///|
let preset_names : Array[String] = [
  "bracketed-segments", "catppuccin-powerline", "gruvbox-rainbow", "jetpack", "nerd-font-symbols",
  "no-empty-icons", "no-nerd-font", "no-runtime-versions", "pastel-powerline", "plain-text-symbols",
  "pure-preset", "tokyo-night",
]

///|
pub fn list_presets() -> Array[String] {
  preset_names.copy()
}

///|
pub fn get_preset(name : String) -> String? {
  match name {
    "bracketed-segments" => Some(preset_bracketed_segments)
    "catppuccin-powerline" => Some(preset_catppuccin_powerline)
    "gruvbox-rainbow" => Some(preset_gruvbox_rainbow)
    "jetpack" => Some(preset_jetpack)
    "nerd-font-symbols" => Some(preset_nerd_font_symbols)
    "no-empty-icons" => Some(preset_no_empty_icons)
    "no-nerd-font" => Some(preset_no_nerd_font)
    "no-runtime-versions" => Some(preset_no_runtime_versions)
    "pastel-powerline" => Some(preset_pastel_powerline)
    "plain-text-symbols" => Some(preset_plain_text_symbols)
    "pure-preset" => Some(preset_pure_preset)
    "tokyo-night" => Some(preset_tokyo_night)
    _ => None
  }
}
