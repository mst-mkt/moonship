///|
pub struct PythonModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  pyenv_version_name : Bool
  pyenv_prefix : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PythonModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "python",
  ),
) -> PythonModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐍 "),
    pyenv_version_name: config.get_prop("pyenv_version_name") == "true",
    pyenv_prefix: config.get_prop("pyenv_prefix", default="pyenv "),
    detect_files: [
      "requirements.txt", ".python-version", "pyproject.toml", "Pipfile", "tox.ini",
      "setup.py", "__init__.py",
    ],
    detect_extensions: [".py", ".ipynb"],
  }
}

///|
pub fn PythonModule::from_config(config : @config.Config) -> PythonModule {
  PythonModule::new(config=config.get_module("python"))
}

///|
pub impl @ms.PromptModule for PythonModule with name(_self) -> String {
  "python"
}

///|
pub impl @ms.PromptModule for PythonModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for PythonModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  let has_env = not(@sys.get_env_var("VIRTUAL_ENV").unwrap_or("").is_empty())
  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
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
    vars["version"] = @exec.add_v_prefix(version)
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
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
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
  let mut last = -1

  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '/' {
      last = i
    }
  }

  if last >= 0 {
    Some(last)
  } else {
    None
  }
}
