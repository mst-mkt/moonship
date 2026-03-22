///|
async test "replace home with ~" {
  assert_eq(
    format_path("/home/user/project", "/home/user", 3, false, None),
    "~/project",
  )
}

///|
async test "root path" {
  assert_eq(format_path("/", "", 3, false, None), "/")
}

///|
async test "home exact match" {
  assert_eq(format_path("/home/user", "/home/user", 3, false, None), "~")
}

///|
async test "deep path truncation" {
  assert_eq(format_path("/a/b/c/d/e", "", 3, false, None), "c/d/e")
}

///|
async test "truncation_length=1" {
  assert_eq(format_path("/a/b/c/d/e", "", 1, false, None), "e")
}

///|
async test "empty path" {
  assert_eq(format_path("", "", 3, false, None), "")
}

///|
async test "no home replacement when home is empty" {
  assert_eq(
    format_path("/home/user/project", "", 3, false, None),
    "/home/user/project",
  )
}

///|
async test "split_path: removes empty segments" {
  assert_eq(split_path("/a//b/"), ["a", "b"])
}

///|
async test "unicode path" {
  assert_eq(
    format_path(
      "/home/user/プロジェクト/src",
      "/home/user",
      3,
      false,
      None,
    ),
    "~/プロジェクト/src",
  )
}

///|
async test "path with spaces" {
  assert_eq(
    format_path("/home/user/my project/src", "/home/user", 3, false, None),
    "~/my project/src",
  )
}

///|
async test "exact truncation boundary" {
  assert_eq(format_path("/a/b/c", "", 3, false, None), "/a/b/c")
}

///|
async test "one over truncation boundary" {
  assert_eq(format_path("/a/b/c/d", "", 3, false, None), "b/c/d")
}

///|
async test "home is prefix of longer dirname" {
  assert_eq(
    format_path("/home/user2/project", "/home/user", 3, false, None),
    "/home/user2/project",
  )
}

///|
async test "truncate_to_repo: relative path" {
  assert_eq(
    format_path(
      "/home/user/repo/src/lib",
      "/home/user",
      3,
      true,
      Some("/home/user/repo"),
    ),
    "repo/src/lib",
  )
}

///|
async test "truncate_to_repo: repo root" {
  assert_eq(
    format_path(
      "/home/user/repo",
      "/home/user",
      3,
      true,
      Some("/home/user/repo"),
    ),
    "repo",
  )
}

///|
async test "truncate_to_repo: deep path truncated" {
  assert_eq(
    format_path(
      "/home/user/repo/a/b/c/d",
      "/home/user",
      3,
      true,
      Some("/home/user/repo"),
    ),
    "b/c/d",
  )
}

///|
async test "truncate_to_repo: false falls back to home" {
  assert_eq(
    format_path(
      "/home/user/repo/src",
      "/home/user",
      3,
      false,
      Some("/home/user/repo"),
    ),
    "~/repo/src",
  )
}

///|
async test "truncate_to_repo: no repo_root" {
  assert_eq(
    format_path("/home/user/project", "/home/user", 3, true, None),
    "~/project",
  )
}

///|
async test "truncate_to_repo: cwd outside repo" {
  assert_eq(
    format_path("/other/path", "/home/user", 3, true, Some("/home/user/repo")),
    "/other/path",
  )
}

///|
async test "custom truncation_symbol" {
  assert_eq(
    format_path("/a/b/c/d/e", "", 3, false, None, truncation_symbol="../"),
    "../c/d/e",
  )
}

///|
async test "custom home_symbol" {
  assert_eq(
    format_path(
      "/home/user/project",
      "/home/user",
      3,
      false,
      None,
      home_symbol="🏠",
    ),
    "🏠/project",
  )
}

///|
async test "execute: custom truncation_symbol" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|truncation_symbol = "../"
      #|truncation_length = 1
    ),
  )
  let ctx = @context.Context::new(cwd="/a/b/c/d/e")
  let m = DirectoryModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  assert_true(out.render().contains("../"))
}

///|
async test "last_path_component" {
  assert_eq(last_path_component("/home/user/project"), "project")
  assert_eq(last_path_component("/"), "/")
}

///|
async test "name" {
  let m : &@ms.PromptModule = DirectoryModule::default()
  assert_eq(m.name(), "directory")
}

///|
async test "disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m : &@ms.PromptModule = DirectoryModule::from_config(config)

  assert_true(m.execute(ctx) is Disabled)
}

// --- execute tests ---

///|
async test "execute: returns Output with path" {
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
  )
  let m = DirectoryModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("project"))
}

///|
async test "execute: custom format" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|format = "dir:[$path]($style)"
    ),
  )
  let ctx = @context.Context::new(
    cwd="/home/user/project",
    home_dir="/home/user",
  )
  let m = DirectoryModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  assert_true(out.render().contains("dir:"))
  assert_true(out.render().contains("project"))
}

///|
async test "execute: truncation applied" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|truncation_length = 1
    ),
  )
  let ctx = @context.Context::new(cwd="/a/b/c/d/e")
  let m = DirectoryModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("e"))
  assert_false(rendered.contains("/a/b/c/d/e"))
}
