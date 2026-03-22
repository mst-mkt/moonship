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
pub fn add_v_prefix(s : String) -> String {
  if s.is_empty() || s.has_prefix("v") || s.has_prefix("V") {
    s
  } else {
    "v" + s
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
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    let ver = extract_semver(s)
    if not(ver.is_empty()) {
      return ver
    }
  }

  ""
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
  let mut dots = 0

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      buf.write_char(c)
    } else if c == '.' {
      dots += 1
      buf.write_char(c)
    } else {
      break
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
pub fn detect_compiler_name(
  output : String,
  compilers : Array[(String, String)],
) -> String {
  for pair in compilers {
    let (name, hint) = pair
    if output.contains(hint) {
      return name
    }
  }

  ""
}

///|
pub fn detect_project(
  cwd : String,
  files : Array[String],
  extensions : Array[String],
  folders? : Array[String] = [],
) -> Bool {
  for file in files {
    if @fs.path_exists(cwd + "/" + file) {
      return true
    }
  }

  for folder in folders {
    if @fs.path_exists(cwd + "/" + folder) {
      return true
    }
  }

  let entries = @fs.read_dir(cwd) catch { _ => return false }

  for entry in entries {
    for ext in extensions {
      if entry.has_suffix(ext) {
        return true
      }
    }
  }

  false
}
