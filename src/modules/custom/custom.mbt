///|
pub struct CustomModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  command : String
  when : String
  require_repo : Bool
  shell : String
  description : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn CustomModule::default() -> CustomModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol($output )]($style)",
    style: "green bold",
    symbol: "",
    command: "",
    when: "",
    require_repo: false,
    shell: "",
    description: "",
    detect_files: [],
    detect_extensions: [],
    detect_folders: [],
  }
}

///|
pub fn CustomModule::from_table(table : @config.ModuleTable) -> CustomModule {
  let d = CustomModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    command: table.get_string("command").unwrap_or(d.command),
    when: table.get_string("when").unwrap_or(d.when),
    require_repo: table.get_bool("require_repo").unwrap_or(d.require_repo),
    shell: table.get_string("shell").unwrap_or(d.shell),
    description: table.get_string("description").unwrap_or(d.description),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn CustomModule::from_config(config : @config.Config) -> CustomModule {
  match config.get_raw_module("custom") {
    Some(table) => CustomModule::from_table(table)
    None => CustomModule::default()
  }
}

///|
pub impl @ms.PromptModule for CustomModule with name(_self) -> String {
  "custom"
}

///|
pub impl @ms.PromptModule for CustomModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for CustomModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard not(self.command.is_empty()) else {
    return Skipped("no command configured")
  }

  // Check require_repo
  if self.require_repo {
    guard ctx.get_repo() is Some(_) else {
      return Skipped("not in a git repository")
    }
  }

  // Check detect conditions
  let has_detect = not(self.detect_files.is_empty()) ||
    not(self.detect_extensions.is_empty()) ||
    not(self.detect_folders.is_empty())

  if has_detect {
    guard @exec.detect_project(
      ctx.cwd,
      self.detect_files,
      self.detect_extensions,
      folders=self.detect_folders,
    ) else {
      return Skipped("detection conditions not met")
    }
  }

  let shell_cmd = if self.shell.is_empty() { "sh" } else { self.shell }

  // Check `when` condition (exit code 0 = pass)
  if not(self.when.is_empty()) {
    let status = @exec.exec_cmd_status(shell_cmd, ["-c", self.when])
    guard status == 0 else {
      return Skipped("when condition not met")
    }
  }
  let output = @exec.exec_cmd(shell_cmd, ["-c", self.command])
  guard not(output.is_empty()) else {
    return Skipped("command produced no output")
  }

  let vars : Map[String, String] = {
    "output": output,
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
pub fn CustomModule::schema() -> @config.ModuleSchema {
  let d = CustomModule::default()
  {
    name: "custom",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      { name: "command", field_type: @config.FString, default_value: d.command },
    ],
  }
}
