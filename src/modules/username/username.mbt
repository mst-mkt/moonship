///|
pub struct UsernameModule {
  disabled : Bool
  format : String
  style_root : String
  style_user : String
  show_always : Bool
}

///|
pub fn UsernameModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "username",
  ),
) -> UsernameModule {
  {
    disabled: config.disabled,
    format: config.format,
    style_root: config.get_prop("style_root", default="bold red"),
    style_user: config.get_prop("style_user", default="bold yellow"),
    show_always: config.get_prop("show_always") == "true",
  }
}

///|
pub fn UsernameModule::from_config(config : @config.Config) -> UsernameModule {
  UsernameModule::new(config=config.get_module("username"))
}

///|
pub impl @ms.PromptModule for UsernameModule with name(_self) -> String {
  "username"
}

///|
pub impl @ms.PromptModule for UsernameModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let user = @sys.get_env_var("USER").unwrap_or("")
  guard not(user.is_empty()) else { return Skipped("USER not set") }

  let is_root = user == "root"
  let is_ssh = is_ssh_session()

  guard self.show_always || is_root || is_ssh else {
    return Skipped("not root or SSH")
  }

  let style_str = if is_root { self.style_root } else { self.style_user }
  let vars : Map[String, String] = { "user": user, "style": style_str }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn is_ssh_session() -> Bool {
  let vars = ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]

  for v in vars {
    if not(@sys.get_env_var(v).unwrap_or("").is_empty()) {
      return true
    }
  }

  false
}
