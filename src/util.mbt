///|
fn get_argv() -> Array[String] {
  let args = @sys.get_cli_args()
  guard args.length() > 1 else { return [] }

  args[1:].to_array()
}

///|
fn build_context(pa : PromptArgs) -> @context.Context {
  let config = load_config()
  let cwd = if pa.path.is_empty() {
    @env.current_dir().unwrap_or(".")
  } else {
    pa.path
  }
  let home_dir = @sys.get_env_var("HOME").unwrap_or("")

  @context.Context::new(
    cwd~,
    home_dir~,
    status=pa.status,
    pipestatus=pa.pipestatus,
    cmd_duration=pa.cmd_duration,
    jobs=pa.jobs,
    terminal_width=pa.terminal_width,
    keymap=pa.keymap,
    shlvl=pa.shlvl,
    config~,
  )
}

///|
fn load_config() -> @config.Config {
  let env_path = @sys.get_env_var("MOONSHIP_CONFIG").unwrap_or("")

  let path = if not(env_path.is_empty()) {
    env_path
  } else {
    let home = @sys.get_env_var("HOME").unwrap_or("")
    guard not(home.is_empty()) else { return @config.Config::default() }
    let config_dir = "\{home}/.config/moonship"
    find_config_file(config_dir)
  }

  guard not(path.is_empty()) else { return @config.Config::default() }

  let content = @fs.read_file_to_string(path) catch {
    e =>
      return @config.Config::default().with_warnings([
        "failed to read '\{path}': \{e}",
      ])
  }

  parse_config(path, content)
}

///|
fn find_config_file(dir : String) -> String {
  [
    "\{dir}/moonship.jsonc",
    "\{dir}/moonship.json",
    "\{dir}/moonship.json5",
    "\{dir}/moonship.toml",
  ]
  .iter()
  .find_first(fn(path) { @fs.path_exists(path) })
  .unwrap_or("")
}

///|
fn parse_config(path : String, content : String) -> @config.Config {
  let is_json = path.has_suffix(".json") ||
    path.has_suffix(".jsonc") ||
    path.has_suffix(".json5")

  if is_json {
    @config.Config::from_json(content) catch {
      e =>
        return @config.Config::default().with_warnings([
          "failed to parse '\{path}': \{e}",
        ])
    }
  } else {
    @config.Config::from_toml(content) catch {
      e =>
        return @config.Config::default().with_warnings([
          "failed to parse '\{path}': \{e}",
        ])
    }
  }
}

///|
fn self_exe() -> String {
  let args = @sys.get_cli_args()
  guard args.length() > 0 else { return "moonship" }

  let arg0 = args[0]

  if arg0.has_prefix("/") {
    return arg0
  }
  if arg0.contains("/") {
    return @env.current_dir().unwrap_or(".") + "/" + arg0
  }

  let path_var = @sys.get_env_var("PATH").unwrap_or("")
  path_var
  .split(":")
  .map(fn(dir) { dir.to_string() })
  .filter(fn(dir) { not(dir.is_empty()) })
  .map(fn(dir) { "\{dir}/\{arg0}" })
  .find_first(fn(candidate) { @fs.path_exists(candidate) })
  .unwrap_or(arg0)
}

///|
fn max_length(iter : Iter[String]) -> Int {
  iter.fold(init=0, fn(max, s) {
    let len = s.length()
    if len > max {
      len
    } else {
      max
    }
  })
}

///|
fn format_duration(ms : Int64) -> String {
  if ms == 0L {
    "<1ms"
  } else {
    "\{ms}ms"
  }
}

///|
fn pad_right(s : String, width : Int) -> String {
  guard s.length() < width else { return s }

  let buf = StringBuilder::new()
  buf.write_string(s)
  for _ in 0..<(width - s.length()) {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
fn pad_left(s : String, width : Int) -> String {
  guard s.length() < width else { return s }

  let buf = StringBuilder::new()
  for _ in 0..<(width - s.length()) {
    buf.write_char(' ')
  }
  buf.write_string(s)
  buf.to_string()
}
