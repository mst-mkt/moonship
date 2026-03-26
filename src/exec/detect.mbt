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

///|
pub fn is_ssh_session() -> Bool {
  ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]
  .iter()
  .any(fn(env_name) {
    not(@sys.get_env_var(env_name).unwrap_or("").is_empty())
  })
}
