///|
pub async fn exec_cmd(cmd : String, args : Array[String]) -> String {
  let (status, data) = @process.collect_stdout(cmd, args[:]) catch {
    _ => return ""
  }

  if status != 0 {
    return ""
  }

  let output = data.text() catch { _ => return "" }
  first_line(output)
}

///|
pub async fn exec_cmd_full(cmd : String, args : Array[String]) -> String {
  let (status, data) = @process.collect_stdout(cmd, args[:]) catch {
    _ => return ""
  }

  if status != 0 {
    return ""
  }

  data.text() catch {
    _ => ""
  }
}

///|
fn first_line(s : String) -> String {
  let line = match s.find("\n") {
    Some(idx) => s[:idx].to_string()
    None => s
  }

  if line.has_suffix("\r") {
    line[:line.length() - 1].to_string()
  } else {
    line
  }
}

///|
pub async fn exec_cmd_status(cmd : String, args : Array[String]) -> Int {
  let (status, _) = @process.collect_stdout(cmd, args[:]) catch { _ => return -1 }
  status
}

///|
pub fn add_v_prefix(s : String) -> String {
  if s.is_empty() || s.has_prefix("v") || s.has_prefix("V") {
    s
  } else {
    "v\{s}"
  }
}

///|
pub fn strip_v_prefix(s : String) -> String {
  if s.has_prefix("v") || s.has_prefix("V") {
    s[1:].to_string()
  } else {
    s
  }
}

///|
pub async fn try_commands(commands : Array[(String, String)]) -> String {
  for pair in commands {
    let (cmd, arg) = pair
    let output = exec_cmd(cmd, [arg])
    if not(output.is_empty()) {
      return output
    }
  }

  ""
}

///|
pub fn find_semver(output : String) -> String {
  output
  .split(" ")
  .map(fn(part) { extract_semver(part.to_string()) })
  .find_first(fn(ver) { not(ver.is_empty()) })
  .unwrap_or("")
}

///|
fn extract_semver(s : String) -> String {
  if s.is_empty() {
    return ""
  }

  let first = s[0].unsafe_to_char()
  if not(first >= '0' && first <= '9') {
    return ""
  }

  let buf = StringBuilder::new()

  let dots = loop (0, 0) {
    (i, dots) =>
      if i >= s.length() {
        break dots
      } else {
        let c = s[i].unsafe_to_char()
        if c >= '0' && c <= '9' {
          buf.write_char(c)
          continue (i + 1, dots)
        } else if c == '.' {
          buf.write_char(c)
          continue (i + 1, dots + 1)
        } else {
          break dots
        }
      }
  }

  if dots >= 2 {
    let result = buf.to_string()
    if result.has_suffix(".") {
      result[:result.length() - 1].to_string()
    } else {
      result
    }
  } else {
    ""
  }
}

///|
pub fn format_version(raw : String, version_format : String) -> String {
  guard not(raw.is_empty()) else { return "" }

  let stripped = strip_v_prefix(raw)
  let parts = stripped.split(".").map(fn(s) { s.to_string() }).collect()

  let major = if parts.length() > 0 { parts[0] } else { "" }
  let minor = if parts.length() > 1 { parts[1] } else { "" }
  let patch = if parts.length() > 2 { parts[2] } else { "" }

  version_format
  .replace(old="${raw}", new=stripped)
  .replace(old="${major}", new=major)
  .replace(old="${minor}", new=minor)
  .replace(old="${patch}", new=patch)
}

///|
pub fn detect_compiler_name(
  output : String,
  compilers : Array[(String, String)],
) -> String {
  compilers
  .iter()
  .find_first(fn(pair) { output.contains(pair.1) })
  .map(fn(pair) { pair.0 })
  .unwrap_or("")
}

///|
pub fn is_ssh_session() -> Bool {
  ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]
  .iter()
  .any(fn(env_name) { not(@sys.get_env_var(env_name).unwrap_or("").is_empty()) })
}

///|
pub fn basename(path : String) -> String {
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
pub fn parent_dir(path : String) -> String {
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
pub fn last_slash(s : String) -> Int? {
  loop s.length() - 1 {
    i => if i < 0 { break None } else if s[i].unsafe_to_char() == '/' {
      break Some(i)
    } else {
      continue i - 1
    }
  }
}

///|
pub fn parse_leading_int(s : String) -> Int {
  s
  .iter()
  .take_while(fn(c) { c >= '0' && c <= '9' })
  .fold(init=0, fn(acc, c) { acc * 10 + (c.to_int() - '0'.to_int()) })
}

///|
pub fn detect_project(
  cwd : String,
  files : Array[String],
  extensions : Array[String],
  folders? : Array[String] = [],
) -> Bool {
  if files.iter().any(fn(file) { @fs.path_exists("\{cwd}/\{file}") }) {
    return true
  }

  if folders.iter().any(fn(folder) { @fs.path_exists("\{cwd}/\{folder}") }) {
    return true
  }

  let entries = @fs.read_dir(cwd) catch { _ => return false }

  entries
  .iter()
  .any(fn(entry) { extensions.iter().any(fn(ext) { entry.has_suffix(ext) }) })
}
