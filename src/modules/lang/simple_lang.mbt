///|
pub struct SimpleLangModule {
  module_name : String
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
  command : String
  command_args : Array[String]
  detect_label : String
  version_extract : (String) -> String
}

///|
pub fn SimpleLangModule::from_table(
  table : @config.ModuleTable,
  defaults : SimpleLangModule,
) -> SimpleLangModule {
  {
    ..defaults,
    disabled: table.get_bool("disabled").unwrap_or(defaults.disabled),
    async_render: table.get_bool("async").unwrap_or(defaults.async_render),
    format: table.get_string("format").unwrap_or(defaults.format),
    style: table.get_string("style").unwrap_or(defaults.style),
    symbol: table.get_string("symbol").unwrap_or(defaults.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(defaults.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(defaults.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(defaults.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(defaults.detect_folders),
  }
}

///|
pub fn SimpleLangModule::from_config(
  config : @config.Config,
  defaults : SimpleLangModule,
) -> SimpleLangModule {
  match config.get_raw_module(defaults.module_name) {
    Some(table) => SimpleLangModule::from_table(table, defaults)
    None => defaults
  }
}

///|
pub impl @ms.PromptModule for SimpleLangModule with name(self) -> String {
  self.module_name
}

///|
pub impl @ms.PromptModule for SimpleLangModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for SimpleLangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no \{self.detect_label} project detected")
  }

  let output = @exec.exec_cmd(self.command, self.command_args)
  guard not(output.is_empty()) else {
    return Skipped("\{self.command} not found")
  }

  let display = (self.version_extract)(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse \{self.command} version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(display, self.version_format),
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
pub fn SimpleLangModule::schema(
  defaults : SimpleLangModule,
) -> @config.ModuleSchema {
  {
    name: defaults.module_name,
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: defaults.disabled.to_string(),
      },
      {
        name: "format",
        field_type: @config.FString,
        default_value: defaults.format,
      },
      {
        name: "style",
        field_type: @config.FString,
        default_value: defaults.style,
      },
      {
        name: "symbol",
        field_type: @config.FString,
        default_value: defaults.symbol,
      },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: defaults.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: defaults.detect_extensions.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: defaults.detect_folders.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: defaults.version_format,
      },
    ],
  }
}
