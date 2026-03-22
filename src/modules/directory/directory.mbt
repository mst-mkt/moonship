///|
pub struct DirectoryModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  truncation_length : Int
  truncate_to_repo : Bool
  truncation_symbol : String
  home_symbol : String
}

///|
pub fn DirectoryModule::default() -> DirectoryModule {
  {
    disabled: false,
    async_render: false,
    format: "[$path]($style)[$read_only]($read_only_style) ",
    style: "cyan bold",
    truncation_length: 3,
    truncate_to_repo: true,
    truncation_symbol: "",
    home_symbol: "~",
  }
}

///|
pub fn DirectoryModule::from_toml_table(
  table : @config.ModuleTable,
) -> DirectoryModule {
  let d = DirectoryModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    truncation_length: @config.get_toml_int(table, "truncation_length").unwrap_or(
      d.truncation_length,
    ),
    truncate_to_repo: @config.get_toml_bool(table, "truncate_to_repo").unwrap_or(
      d.truncate_to_repo,
    ),
    truncation_symbol: @config.get_toml_string(table, "truncation_symbol").unwrap_or(
      d.truncation_symbol,
    ),
    home_symbol: @config.get_toml_string(table, "home_symbol").unwrap_or(
      d.home_symbol,
    ),
  }
}

///|
pub fn DirectoryModule::from_config(config : @config.Config) -> DirectoryModule {
  match config.get_raw_module("directory") {
    Some(table) => DirectoryModule::from_toml_table(table)
    None => DirectoryModule::default()
  }
}

///|
pub impl @ms.PromptModule for DirectoryModule with name(_self) -> String {
  "directory"
}

///|
pub impl @ms.PromptModule for DirectoryModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DirectoryModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let repo_root = if self.truncate_to_repo {
    ctx.get_repo().map(fn(repo) { repo.repo_root() })
  } else {
    None
  }

  let path = format_path(
    ctx.cwd,
    ctx.home_dir,
    self.truncation_length,
    self.truncate_to_repo,
    repo_root,
    truncation_symbol=self.truncation_symbol,
    home_symbol=self.home_symbol,
  )
  let vars : Map[String, String] = { "path": path, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn format_path(
  cwd : String,
  home : String,
  truncation_length : Int,
  truncate_to_repo : Bool,
  repo_root : String?,
  truncation_symbol? : String = "",
  home_symbol? : String = "~",
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
    _ => replace_home(cwd, home, home_symbol)
  }

  truncate_path(display, truncation_length, truncation_symbol)
}

///|
fn replace_home(cwd : String, home : String, home_symbol : String) -> String {
  let is_home = not(home.is_empty()) &&
    cwd.has_prefix(home) &&
    (
      cwd.length() == home.length() ||
      cwd[home.length():].to_string().has_prefix("/")
    )

  if is_home {
    home_symbol + cwd[home.length():].to_string()
  } else {
    cwd
  }
}

///|
fn truncate_path(
  display : String,
  truncation_length : Int,
  truncation_symbol : String,
) -> String {
  let parts = split_path(display)

  if parts.length() > truncation_length {
    let start = parts.length() - truncation_length
    truncation_symbol + parts[start:].to_array().join("/")
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
