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
pub fn strip_v_prefix(s : String) -> String {
  if s.has_prefix("v") || s.has_prefix("V") {
    s[1:].to_string()
  } else {
    s
  }
}

///|
pub fn detect_project(
  cwd : String,
  files : Array[String],
  extensions : Array[String],
) -> Bool {
  for file in files {
    if @fs.path_exists(cwd + "/" + file) {
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
