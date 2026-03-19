///|
pub struct DirectoryModule {}

///|
pub fn DirectoryModule::new() -> DirectoryModule {
  DirectoryModule::{  }
}

///|
pub impl @ms.PromptModule for DirectoryModule with name(_self) -> String {
  "directory"
}

///|
pub impl @ms.PromptModule for DirectoryModule with execute(
  _self,
  ctx : @context.Context,
) -> @ms.ModuleOutput? {
  let config = ctx.config.get_module("directory")
  guard not(config.disabled) else { return None }

  let truncation_length = config.get_int_prop("truncation_length", default=3)
  let truncate_to_repo = config.get_prop("truncate_to_repo") == "true"
  let repo_root = ctx.git_info.map(fn(info) { info.repo_root })
  let path = format_path(
    ctx.cwd,
    ctx.home_dir,
    truncation_length,
    truncate_to_repo,
    repo_root,
  )
  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = { "path": path }
  let segments = @ms.format_string(config.format, vars, style)

  Some(@ms.ModuleOutput::new(segments))
}

///|
fn format_path(
  cwd : String,
  home : String,
  truncation_length : Int,
  truncate_to_repo : Bool,
  repo_root : String?,
) -> String {
  let display = match (truncate_to_repo, repo_root) {
    (true, Some(root)) if cwd.has_prefix(root) => {
      let relative = if cwd.length() > root.length() {
        cwd[root.length():].to_string()
      } else {
        ""
      }
      last_path_component(root) + relative
    }
    _ => replace_home(cwd, home)
  }

  truncate_path(display, truncation_length)
}

///|
fn replace_home(cwd : String, home : String) -> String {
  let is_home = not(home.is_empty()) &&
    cwd.has_prefix(home) &&
    (
      cwd.length() == home.length() ||
      cwd[home.length():].to_string().has_prefix("/")
    )

  if is_home {
    "~" + cwd[home.length():].to_string()
  } else {
    cwd
  }
}

///|
fn truncate_path(display : String, truncation_length : Int) -> String {
  let parts = split_path(display)

  if parts.length() > truncation_length {
    let start = parts.length() - truncation_length
    "…/" + parts[start:].to_array().join("/")
  } else {
    display
  }
}

///|
fn last_path_component(path : String) -> String {
  split_path(path).last().unwrap_or(path)
}

///|
fn split_path(path : String) -> Array[String] {
  path
  .split("/")
  .map(fn(sv) { sv.to_string() })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
}
