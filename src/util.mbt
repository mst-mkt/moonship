///|
fn get_argv() -> Array[String] {
  let args = @sys.get_cli_args()
  guard args.length() > 1 else { return [] }

  args[1:].to_array()
}

///|
fn build_context(pa : PromptArgs) -> @context.Context {
  let config = load_config()
  let cwd = @env.current_dir().unwrap_or(".")
  let home_dir = @sys.get_env_var("HOME").unwrap_or("")

  @context.Context::new(
    cwd~,
    home_dir~,
    status=pa.status,
    cmd_duration=pa.cmd_duration,
    jobs=pa.jobs,
    terminal_width=pa.terminal_width,
    config~,
  )
}

///|
fn load_config() -> @config.Config {
  let path = @sys.get_env_var("MOONSHIP_CONFIG").unwrap_or("")
  let path = if not(path.is_empty()) {
    path
  } else {
    let home = @sys.get_env_var("HOME").unwrap_or("")
    guard not(home.is_empty()) else { return @config.Config::default() }
    "\{home}/.config/moonship/moonship.toml"
  }

  let content = @fs.read_file_to_string(path) catch {
    _ => return @config.Config::default()
  }

  @config.Config::from_toml(content) catch {
    _ => @config.Config::default()
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
  .map(fn(dir) { dir + "/" + arg0 })
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
