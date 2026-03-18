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
  let path = format_path(ctx.cwd, ctx.home_dir, truncation_length)
  let style = @terminal.parse_style(config.style)
  let vars : Map[String, String] = { "path": path }
  let segments = @ms.format_string(config.format, vars, style)

  Some(@ms.ModuleOutput::new(segments))
}

///|
fn format_path(cwd : String, home : String, truncation_length : Int) -> String {
  let display = if not(home.is_empty()) &&
    cwd.has_prefix(home) &&
    (
      cwd.length() == home.length() ||
      cwd[home.length():].to_string().has_prefix("/")
    ) {
    "~" + cwd[home.length():].to_string()
  } else {
    cwd
  }

  let parts = split_path(display)
  if parts.length() > truncation_length {
    let start = parts.length() - truncation_length
    "…/" + parts[start:].to_array().join("/")
  } else {
    display
  }
}

///|
fn split_path(path : String) -> Array[String] {
  path
  .split("/")
  .map(fn(sv) { sv.to_string() })
  .filter(fn(s) { not(s.is_empty()) })
  .collect()
}
