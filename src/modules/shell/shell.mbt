///|
pub struct ShellModule {
  disabled : Bool
  format : String
  style : String
  bash_indicator : String
  fish_indicator : String
  zsh_indicator : String
  unknown_indicator : String
}

///|
pub fn ShellModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("shell"),
) -> ShellModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    bash_indicator: config.get_prop("bash_indicator", default="bsh"),
    fish_indicator: config.get_prop("fish_indicator", default="fsh"),
    zsh_indicator: config.get_prop("zsh_indicator", default="zsh"),
    unknown_indicator: config.get_prop("unknown_indicator", default=""),
  }
}

///|
pub fn ShellModule::from_config(config : @config.Config) -> ShellModule {
  ShellModule::new(config=config.get_module("shell"))
}

///|
pub impl @ms.PromptModule for ShellModule with name(_self) -> String {
  "shell"
}

///|
pub impl @ms.PromptModule for ShellModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for ShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let shell_name = @sys.get_env_var("MOONSHIP_SHELL").unwrap_or("")
  guard not(shell_name.is_empty()) else { return Skipped("shell not detected") }

  let indicator = match shell_name {
    "bash" => self.bash_indicator
    "fish" => self.fish_indicator
    "zsh" => self.zsh_indicator
    _ => self.unknown_indicator
  }

  let vars : Map[String, String] = {
    "indicator": indicator,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
