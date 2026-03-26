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
  let (status, _) = @process.collect_stdout(cmd, args[:]) catch {
    _ => return -1
  }
  status
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
