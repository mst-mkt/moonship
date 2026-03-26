///|
pub struct PythonModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  python_binary : Array[String]
  pyenv_version_name : Bool
  pyenv_prefix : String
  detect_env_vars : Array[String]
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn PythonModule::default() -> PythonModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$pyenv_prefix($version )(\\($virtualenv\\) )]($style)",
    style: "yellow bold",
    symbol: "🐍 ",
    version_format: "v${raw}",
    python_binary: ["python", "python3", "python2"],
    pyenv_version_name: false,
    pyenv_prefix: "pyenv ",
    detect_env_vars: ["VIRTUAL_ENV"],
    detect_files: [
      "requirements.txt", ".python-version", "pyproject.toml", "Pipfile", "tox.ini",
      "setup.py", "__init__.py",
    ],
    detect_extensions: [".py", ".ipynb"],
    detect_folders: [],
  }
}

///|
pub fn PythonModule::from_table(table : @config.ModuleTable) -> PythonModule {
  let d = PythonModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    python_binary: table
    .get_string_array("python_binary")
    .unwrap_or(d.python_binary),
    pyenv_version_name: table
    .get_bool("pyenv_version_name")
    .unwrap_or(d.pyenv_version_name),
    pyenv_prefix: table.get_string("pyenv_prefix").unwrap_or(d.pyenv_prefix),
    detect_env_vars: table
    .get_string_array("detect_env_vars")
    .unwrap_or(d.detect_env_vars),
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
pub fn PythonModule::from_config(config : @config.Config) -> PythonModule {
  match config.get_raw_module("python") {
    Some(table) => PythonModule::from_table(table)
    None => PythonModule::default()
  }
}

///|
pub impl @ms.PromptModule for PythonModule with name(_self) -> String {
  "python"
}

///|
pub impl @ms.PromptModule for PythonModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PythonModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  let has_env = not(@sys.get_env_var("VIRTUAL_ENV").unwrap_or("").is_empty())
  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions, folders=self.detect_folders) else {
    return Skipped("no Python project detected")
  }

  let version = get_python_version(self.pyenv_version_name)
  let virtualenv = get_virtualenv_name()
  let pyenv_prefix = if self.pyenv_version_name {
    self.pyenv_prefix
  } else {
    ""
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
    "pyenv_prefix": pyenv_prefix,
  }

  if not(version.is_empty()) {
    vars["version"] = @exec.format_version(version, self.version_format)
  }

  if not(virtualenv.is_empty()) {
    vars["virtualenv"] = virtualenv
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
async fn get_python_version(pyenv_version_name : Bool) -> String {
  if pyenv_version_name {
    let env_ver = @sys.get_env_var("PYENV_VERSION").unwrap_or("")
    if not(env_ver.is_empty()) {
      return env_ver
    }

    let pyenv_out = @exec.exec_cmd("pyenv", ["version-name"])
    if not(pyenv_out.is_empty()) {
      return pyenv_out
    }
  }

  let binaries = ["python", "python3", "python2"]
  for binary in binaries {
    let output = @exec.exec_cmd(binary, ["--version"])
    if not(output.is_empty()) {
      return parse_python_version(output)
    }
  }

  ""
}

///|
fn parse_python_version(output : String) -> String {
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() >= 2 {
    parts[1]
  } else {
    output
  }
}

///|
fn get_virtualenv_name() -> String {
  let venv_path = @sys.get_env_var("VIRTUAL_ENV").unwrap_or("")
  if venv_path.is_empty() {
    return ""
  }

  let name = basename(venv_path)

  let generic_names = [".venv", "venv", "env", ".env"]
  if generic_names.contains(name) {
    return basename(parent_dir(venv_path))
  }

  name
}

///|
fn basename(path : String) -> String {
  let trimmed = if path.has_suffix("/") {
    path[:path.length() - 1].to_string()
  } else {
    path
  }

  match last_slash(trimmed) {
    Some(idx) => trimmed[idx + 1:].to_string()
    None => trimmed
  }
}

///|
fn parent_dir(path : String) -> String {
  let trimmed = if path.has_suffix("/") {
    path[:path.length() - 1].to_string()
  } else {
    path
  }

  match last_slash(trimmed) {
    Some(idx) => trimmed[:idx].to_string()
    None => ""
  }
}

///|
fn last_slash(s : String) -> Int? {
  let init : (Int?, Int) = (None, 0)

  s
  .iter()
  .fold(init~, fn(acc, ch) {
    let (result, i) = acc
    (if ch == '/' { Some(i) } else { result }, i + 1)
  }).0
}

///|
pub fn PythonModule::schema() -> @config.ModuleSchema {
  let d = PythonModule::default()
  {
    name: "python",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "pyenv_version_name",
        field_type: @config.FBool,
        default_value: d.pyenv_version_name.to_string(),
      },
      {
        name: "pyenv_prefix",
        field_type: @config.FString,
        default_value: d.pyenv_prefix,
      },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
