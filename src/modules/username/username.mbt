///|
pub struct UsernameModule {
  disabled : Bool
  async_render : Bool
  format : String
  style_root : String
  style_user : String
  show_always : Bool
}

///|
pub fn UsernameModule::default() -> UsernameModule {
  {
    disabled: false,
    async_render: false,
    format: "[$user]($style) in ",
    style_root: "red bold",
    style_user: "yellow bold",
    show_always: false,
  }
}

///|
pub fn UsernameModule::from_table(
  table : @config.ModuleTable,
) -> UsernameModule {
  let d = UsernameModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style_root: table.get_string("style_root").unwrap_or(d.style_root),
    style_user: table.get_string("style_user").unwrap_or(d.style_user),
    show_always: table.get_bool("show_always").unwrap_or(d.show_always),
  }
}

///|
pub fn UsernameModule::from_config(config : @config.Config) -> UsernameModule {
  match config.get_raw_module("username") {
    Some(table) => UsernameModule::from_table(table)
    None => UsernameModule::default()
  }
}

///|
pub impl @ms.PromptModule for UsernameModule with name(_self) -> String {
  "username"
}

///|
pub impl @ms.PromptModule for UsernameModule with is_async(self) -> Bool {
  self.async_render
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
  ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]
  .iter()
  .any(fn(v) { not(@sys.get_env_var(v).unwrap_or("").is_empty()) })
}

///|
pub fn UsernameModule::schema() -> @config.ModuleSchema {
  let d = UsernameModule::default()
  {
    name: "username",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      {
        name: "style_root",
        field_type: @config.FString,
        default_value: d.style_root,
      },
      {
        name: "style_user",
        field_type: @config.FString,
        default_value: d.style_user,
      },
      {
        name: "show_always",
        field_type: @config.FBool,
        default_value: d.show_always.to_string(),
      },
    ],
  }
}
