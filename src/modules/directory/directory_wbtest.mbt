///|
test "replace home with ~" {
  assert_eq(
    format_path("/home/user/project", "/home/user", 3, false, None),
    "~/project",
  )
}

///|
test "root path" {
  assert_eq(format_path("/", "", 3, false, None), "/")
}

///|
test "home exact match" {
  assert_eq(format_path("/home/user", "/home/user", 3, false, None), "~")
}

///|
test "deep path truncation" {
  assert_eq(format_path("/a/b/c/d/e", "", 3, false, None), "…/c/d/e")
}

///|
test "truncation_length=1" {
  assert_eq(format_path("/a/b/c/d/e", "", 1, false, None), "…/e")
}

///|
test "empty path" {
  assert_eq(format_path("", "", 3, false, None), "")
}

///|
test "no home replacement when home is empty" {
  assert_eq(
    format_path("/home/user/project", "", 3, false, None),
    "/home/user/project",
  )
}

///|
test "split_path: removes empty segments" {
  assert_eq(split_path("/a//b/"), ["a", "b"])
}

///|
test "unicode path" {
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
test "path with spaces" {
  assert_eq(
    format_path("/home/user/my project/src", "/home/user", 3, false, None),
    "~/my project/src",
  )
}

///|
test "exact truncation boundary" {
  assert_eq(format_path("/a/b/c", "", 3, false, None), "/a/b/c")
}

///|
test "one over truncation boundary" {
  assert_eq(format_path("/a/b/c/d", "", 3, false, None), "…/b/c/d")
}

///|
test "home is prefix of longer dirname" {
  assert_eq(
    format_path("/home/user2/project", "/home/user", 3, false, None),
    "/home/user2/project",
  )
}

///|
test "truncate_to_repo: relative path" {
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
test "truncate_to_repo: repo root" {
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
test "truncate_to_repo: deep path truncated" {
  assert_eq(
    format_path(
      "/home/user/repo/a/b/c/d",
      "/home/user",
      3,
      true,
      Some("/home/user/repo"),
    ),
    "…/b/c/d",
  )
}

///|
test "truncate_to_repo: false falls back to home" {
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
test "truncate_to_repo: no repo_root" {
  assert_eq(
    format_path("/home/user/project", "/home/user", 3, true, None),
    "~/project",
  )
}

///|
test "truncate_to_repo: cwd outside repo" {
  assert_eq(
    format_path("/other/path", "/home/user", 3, true, Some("/home/user/repo")),
    "/other/path",
  )
}

///|
test "execute with git_info truncates to repo" {
  let git_info = @git.GitInfo::new(repo_root="/home/user/repo", branch="main")
  let ctx = @context.Context::new(
    cwd="/home/user/repo/src",
    home_dir="/home/user",
    git_info=Some(git_info),
  )
  let m : &@ms.PromptModule = DirectoryModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("repo/src"))
  assert_false(rendered.contains("~"))
}

///|
test "last_path_component" {
  assert_eq(last_path_component("/home/user/project"), "project")
  assert_eq(last_path_component("/"), "/")
}

///|
test "name" {
  let m : &@ms.PromptModule = DirectoryModule::new()
  assert_eq(m.name(), "directory")
}

///|
test "disabled returns None" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|disabled = true
      #|
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m : &@ms.PromptModule = DirectoryModule::new()

  assert_true(m.execute(ctx) is None)
}
