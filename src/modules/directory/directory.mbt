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
  repo_root_format : String
  repo_root_style : String
  before_repo_root_style : String
  read_only : String
  read_only_style : String
  use_logical_path : Bool
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
    repo_root_format: "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ",
    repo_root_style: "",
    before_repo_root_style: "",
    read_only: "🔒",
    read_only_style: "red",
    use_logical_path: true,
  }
}

///|
pub fn DirectoryModule::from_table(
  table : @config.ModuleTable,
) -> DirectoryModule {
  let d = DirectoryModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
    truncate_to_repo: table
    .get_bool("truncate_to_repo")
    .unwrap_or(d.truncate_to_repo),
    truncation_symbol: table
    .get_string("truncation_symbol")
    .unwrap_or(d.truncation_symbol),
    home_symbol: table.get_string("home_symbol").unwrap_or(d.home_symbol),
    repo_root_format: table
    .get_string("repo_root_format")
    .unwrap_or(d.repo_root_format),
    repo_root_style: table
    .get_string("repo_root_style")
    .unwrap_or(d.repo_root_style),
    before_repo_root_style: table
    .get_string("before_repo_root_style")
    .unwrap_or(d.before_repo_root_style),
    read_only: table.get_string("read_only").unwrap_or(d.read_only),
    read_only_style: table
    .get_string("read_only_style")
    .unwrap_or(d.read_only_style),
    use_logical_path: table
    .get_bool("use_logical_path")
    .unwrap_or(d.use_logical_path),
  }
}

///|
pub fn DirectoryModule::from_config(config : @config.Config) -> DirectoryModule {
  match config.get_raw_module("directory") {
    Some(table) => DirectoryModule::from_table(table)
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

  let repo_root = ctx.get_repo().map(fn(repo) { repo.repo_root() })
  let display_dir = if self.use_logical_path { ctx.logical_dir } else { ctx.cwd }
  let is_read_only = not(is_writable(ctx.cwd))
  let read_only_val = if is_read_only { self.read_only } else { "" }

  let (format, vars) = match repo_root {
    Some(root) if not(self.repo_root_style.is_empty()) && display_dir.has_prefix(root) => {
      let (before_root_path, repo_root_name, path_in_repo) = build_repo_root_parts(
        display_dir, root, ctx.home_dir, self.home_symbol,
      )
      let vars : Map[String, String] = {
        "before_root_path": before_root_path,
        "repo_root": repo_root_name,
        "path": path_in_repo,
        "style": self.style,
        "repo_root_style": self.repo_root_style,
        "before_repo_root_style": if self.before_repo_root_style.is_empty() {
          self.style
        } else {
          self.before_repo_root_style
        },
        "read_only": read_only_val,
        "read_only_style": self.read_only_style,
      }
      (self.repo_root_format, vars)
    }
    _ => {
      let effective_root = if self.truncate_to_repo { repo_root } else { None }
      let path = format_path(
        display_dir,
        ctx.home_dir,
        self.truncation_length,
        self.truncate_to_repo,
        effective_root,
        truncation_symbol=self.truncation_symbol,
        home_symbol=self.home_symbol,
      )
      let vars : Map[String, String] = {
        "path": path,
        "style": self.style,
        "read_only": read_only_val,
        "read_only_style": self.read_only_style,
      }
      (self.format, vars)
    }
  }

  let segments = @ms.format_string(format, vars, @terminal.Style::default())
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

///|
fn build_repo_root_parts(
  cwd : String,
  repo_root : String,
  home : String,
  home_symbol : String,
) -> (String, String, String) {
  guard cwd.has_prefix(repo_root) else { return ("", "", cwd) }

  let repo_name = last_path_component(repo_root)

  let before_root = if repo_root.length() > repo_name.length() {
    let parent = repo_root[:repo_root.length() - repo_name.length()].to_string()
    let replaced = replace_home(parent, home, home_symbol)

    if replaced.has_suffix("/") {
      replaced
    } else {
      replaced + "/"
    }
  } else {
    ""
  }

  let after_root = if cwd.length() > repo_root.length() {
    cwd[repo_root.length():].to_string()
  } else {
    ""
  }

  (before_root, repo_name, after_root)
}

///|
fn is_writable(path : String) -> Bool {
  // Try to create a temp file to check writability
  let test_path = path + "/.moonship_write_test"

  @fs.write_string_to_file(test_path, "") catch { _ => return false }

  @fs.remove_file(test_path) catch { _ => () }
  true
}

///|
pub fn DirectoryModule::schema() -> @config.ModuleSchema {
  let d = DirectoryModule::default()
  {
    name: "directory",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "truncation_length",
        field_type: @config.FInt,
        default_value: d.truncation_length.to_string(),
      },
      {
        name: "truncate_to_repo",
        field_type: @config.FBool,
        default_value: d.truncate_to_repo.to_string(),
      },
      {
        name: "truncation_symbol",
        field_type: @config.FString,
        default_value: d.truncation_symbol,
      },
      {
        name: "home_symbol",
        field_type: @config.FString,
        default_value: d.home_symbol,
      },
      {
        name: "repo_root_format",
        field_type: @config.FString,
        default_value: d.repo_root_format,
      },
      {
        name: "repo_root_style",
        field_type: @config.FString,
        default_value: d.repo_root_style,
      },
      {
        name: "before_repo_root_style",
        field_type: @config.FString,
        default_value: d.before_repo_root_style,
      },
      {
        name: "read_only",
        field_type: @config.FString,
        default_value: d.read_only,
      },
      {
        name: "read_only_style",
        field_type: @config.FString,
        default_value: d.read_only_style,
      },
      {
        name: "use_logical_path",
        field_type: @config.FBool,
        default_value: d.use_logical_path.to_string(),
      },
    ],
  }
}
