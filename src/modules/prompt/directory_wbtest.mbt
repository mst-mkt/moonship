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

///|
async test "execute: use_logical_path displays logical_dir" {
  let ctx = @context.Context::new(cwd="/real/path", logical_dir="/virtual/path")
  let m = DirectoryModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("virtual"))
  assert_false(rendered.contains("real"))
}

///|
async test "execute: use_logical_path=false displays cwd" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|use_logical_path = false
    ),
  )
  let ctx = @context.Context::new(
    cwd="/real/path",
    logical_dir="/virtual/path",
    config~,
  )
  let m = DirectoryModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("real"))
  assert_false(rendered.contains("virtual"))
}

// --- build_repo_root_parts tests ---

///|
test "build_repo_root_parts: basic" {
  let (before, root, after) = build_repo_root_parts(
    "/home/user/repos/myproject/src/lib", "/home/user/repos/myproject", "/home/user",
    "~",
  )
  assert_eq(before, "~/repos/")
  assert_eq(root, "myproject")
  assert_eq(after, "/src/lib")
}

///|
test "build_repo_root_parts: at repo root" {
  let (before, root, after) = build_repo_root_parts(
    "/home/user/myproject", "/home/user/myproject", "/home/user", "~",
  )
  assert_eq(before, "~/")
  assert_eq(root, "myproject")
  assert_eq(after, "")
}

///|
test "build_repo_root_parts: no home match" {
  let (before, root, after) = build_repo_root_parts(
    "/opt/repos/project/src", "/opt/repos/project", "/home/user", "~",
  )
  assert_eq(before, "/opt/repos/")
  assert_eq(root, "project")
  assert_eq(after, "/src")
}

///|
test "build_repo_root_parts: cwd not under repo_root" {
  let (before, root, after) = build_repo_root_parts(
    "/other/path", "/home/user/project", "/home/user", "~",
  )
  assert_eq(before, "")
  assert_eq(root, "")
  assert_eq(after, "/other/path")
}

///|
async test "execute: repo_root_format used when repo_root_style set" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|repo_root_style = "bold green"
    ),
  )
  let m = DirectoryModule::from_config(config)

  // Use this project's own root as test path
  let path = @env.current_dir().unwrap_or(".")
  let ctx = @context.Context::new(cwd=path, config~)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  // bold green = "1;32m", should appear for repo root name
  assert_true(rendered.contains(";32m"))
  ctx.close_repo()
}

///|
async test "execute: before_repo_root_style falls back to style" {
  let config = @config.Config::from_toml(
    (
      #|[directory]
      #|repo_root_style = "bold green"
    ),
  )
  let m = DirectoryModule::from_config(config)

  // before_repo_root_style is empty -> fallback to style (cyan bold = ";36m")
  assert_eq(m.before_repo_root_style, "")

  let path = @env.current_dir().unwrap_or(".")
  let ctx = @context.Context::new(cwd=path + "/src/modules", config~)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  // style is "cyan bold" = "1;36m" which should be used for before_repo_root
  assert_true(rendered.contains(";36m"))
  ctx.close_repo()
}

///|
async test "execute: repo_root_style empty uses normal format" {
  let m = DirectoryModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.contains("tmp"))
}

// --- fish style tests ---

///|
test "apply_fish_style: abbreviate intermediate dirs" {
  assert_eq(apply_fish_style("~/repos/project/src/lib", 1), "~/r/p/s/lib")
}

///|
test "apply_fish_style: char_count=2" {
  assert_eq(apply_fish_style("~/repos/project/src/lib", 2), "~/re/pr/sr/lib")
}

///|
test "apply_fish_style: absolute path" {
  assert_eq(apply_fish_style("/home/user/project/src", 1), "/h/u/p/src")
}

///|
test "apply_fish_style: single component" {
  assert_eq(apply_fish_style("project", 1), "project")
}

///|
test "apply_fish_style: home only" {
  assert_eq(apply_fish_style("~", 1), "~")
}

///|
test "apply_fish_style: short dirs unchanged" {
  assert_eq(apply_fish_style("~/a/b/lib", 1), "~/a/b/lib")
}

///|
test "apply_fish_style: empty path" {
  assert_eq(apply_fish_style("", 1), "")
}

///|
test "apply_fish_style: root path" {
  assert_eq(apply_fish_style("/", 1), "/")
}

///|
test "apply_fish_style: char_count larger than component" {
  assert_eq(apply_fish_style("~/ab/cd/lib", 5), "~/ab/cd/lib")
}

///|
test "format_path: fish_style with truncation" {
  assert_eq(
    format_path("/a/bb/cc/dd/ee", "", 3, false, None, fish_style=1),
    "c/d/ee",
  )
}

///|
test "format_path: fish_style disabled when substitutions active" {
  assert_eq(
    format_path(
      "/home/user/repos/project/src",
      "/home/user",
      10,
      false,
      None,
      substitutions=[("~/repos", "R")],
      fish_style=1,
    ),
    "R/project/src",
  )
}

///|
test "format_path: with fish_style" {
  assert_eq(
    format_path(
      "/home/user/repos/project/src/lib",
      "/home/user",
      10,
      false,
      None,
      fish_style=1,
    ),
    "~/r/p/s/lib",
  )
}

// --- substitutions tests ---

///|
test "apply_substitutions: basic" {
  let result = apply_substitutions("~/Documents/project", [
    ("~/Documents", "docs"),
  ])
  assert_eq(result, "docs/project")
}

///|
test "apply_substitutions: multiple" {
  let result = apply_substitutions("~/repos/myproject", [
    ("~/repos", "R"),
    ("myproject", "MP"),
  ])
  assert_eq(result, "R/MP")
}

///|
test "apply_substitutions: no match" {
  let result = apply_substitutions("~/code/project", [("~/docs", "D")])
  assert_eq(result, "~/code/project")
}

///|
test "apply_substitutions: empty list" {
  assert_eq(apply_substitutions("~/path", []), "~/path")
}

///|
test "format_path: with substitutions" {
  assert_eq(
    format_path("/home/user/Documents/project", "/home/user", 3, false, None, substitutions=[
      ("~/Documents", "docs"),
    ]),
    "docs/project",
  )
}

///|
async test "is_writable: writable directory" {
  assert_true(is_writable("/tmp"))
}

///|
async test "is_writable: non-writable directory" {
  assert_false(is_writable("/root"))
}

///|
async test "execute: logical_dir defaults to cwd when empty" {
  let ctx = @context.Context::new(cwd="/some/path")

  assert_eq(ctx.logical_dir, "/some/path")
}

// --- edge cases ---

///|
test "format_path: empty cwd" {
  assert_eq(format_path("", "/home/user", 3, false, None), "")
}

///|
test "format_path: cwd is root" {
  assert_eq(format_path("/", "/home/user", 3, false, None), "/")
}

///|
test "format_path: home is empty string no substitution" {
  // With empty home, no ~ replacement, truncation_length=3 keeps 3 components
  assert_eq(
    format_path("/home/user/project", "", 3, false, None),
    "/home/user/project",
  )
}

///|
test "format_path: truncation_length zero means no limit" {
  assert_eq(format_path("/a/b/c", "", 0, false, None), "/a/b/c")
}

///|
test "format_path: truncation_length very large" {
  assert_eq(format_path("/a/b/c", "", 100, false, None), "/a/b/c")
}

///|
test "format_path: home equals cwd" {
  assert_eq(format_path("/home/user", "/home/user", 3, false, None), "~")
}

///|
test "truncate_path: empty path" {
  assert_eq(truncate_path("", 3, "…"), "")
}

///|
test "last_path_component: root path returns slash" {
  // split_path("/") returns [], so last() returns the path itself
  assert_eq(last_path_component("/"), "/")
}

///|
test "last_path_component: single component" {
  assert_eq(last_path_component("project"), "project")
}

///|
test "split_path: empty string" {
  assert_eq(split_path(""), [])
}

///|
test "split_path: root only" {
  assert_eq(split_path("/"), [])
}

///|
test "apply_fish_style: single component unchanged" {
  assert_eq(apply_fish_style("project", 1), "project")
}

///|
test "apply_fish_style: home prefix preserved" {
  assert_eq(apply_fish_style("~/long_dir/sub/project", 1), "~/l/s/project")
}

///|
test "apply_substitutions: empty substitutions" {
  assert_eq(apply_substitutions("~/Documents", []), "~/Documents")
}

///|
test "apply_substitutions: multiple substitutions applied in order" {
  assert_eq(
    apply_substitutions("~/Documents/work", [
      ("~/Documents", "docs"),
      ("work", "w"),
    ]),
    "docs/w",
  )
}

///|
test "build_repo_root_parts: cwd not in repo" {
  let (before, root, after) = build_repo_root_parts(
    "/other/path", "/repo", "/home", "~",
  )
  assert_eq(before, "")
  assert_eq(root, "")
  assert_eq(after, "/other/path")
}

// --- repo root + substitutions: full-path substitution ---

///|
test "substitutions on full path: single component" {
  // Substitution "Documents" → "📁" applied to before part
  let (raw_before, raw_root, raw_after) = build_repo_root_parts(
    "/home/user/Documents/myrepo/src", "/home/user/Documents/myrepo", "/home/user",
    "~",
  )
  let subs : Array[(String, String)] = [("Documents", "📁")]

  let full = raw_before + raw_root + raw_after
  let substituted_full = apply_substitutions(full, subs)
  let sub_before = apply_substitutions(raw_before, subs)
  let sub_root = apply_substitutions(raw_root, subs)
  let sub_after = apply_substitutions(raw_after, subs)

  // Per-part matches full-path substitution
  assert_eq(sub_before + sub_root + sub_after, substituted_full)
  assert_eq(sub_before, "~/📁/")
  assert_eq(sub_root, "myrepo")
  assert_eq(sub_after, "/src")
}

///|
test "substitutions on full path: boundary-spanning pattern" {
  // Substitution "Documents/myrepo" → "project" spans before+root boundary
  let (raw_before, raw_root, raw_after) = build_repo_root_parts(
    "/home/user/Documents/myrepo/src", "/home/user/Documents/myrepo", "/home/user",
    "~",
  )
  let subs : Array[(String, String)] = [("Documents/myrepo", "project")]

  let full = raw_before + raw_root + raw_after
  let substituted_full = apply_substitutions(full, subs)
  let sub_before = apply_substitutions(raw_before, subs)
  let sub_root = apply_substitutions(raw_root, subs)
  let sub_after = apply_substitutions(raw_after, subs)

  // Per-part does NOT match full-path substitution (boundary-spanning)
  assert_true(sub_before + sub_root + sub_after != substituted_full)
  assert_eq(substituted_full, "~/project/src")

  // Fallback: full substituted path used as path
  let (before, root, path) = if sub_before + sub_root + sub_after ==
    substituted_full {
    (sub_before, sub_root, sub_after)
  } else {
    ("", "", substituted_full)
  }
  assert_eq(before, "")
  assert_eq(root, "")
  assert_eq(path, "~/project/src")
}

///|
test "substitutions on full path: no substitutions" {
  let (raw_before, raw_root, raw_after) = build_repo_root_parts(
    "/home/user/repos/myproject/src", "/home/user/repos/myproject", "/home/user",
    "~",
  )
  let subs : Array[(String, String)] = []

  let full = raw_before + raw_root + raw_after
  let substituted_full = apply_substitutions(full, subs)
  let sub_before = apply_substitutions(raw_before, subs)
  let sub_root = apply_substitutions(raw_root, subs)
  let sub_after = apply_substitutions(raw_after, subs)

  assert_eq(sub_before + sub_root + sub_after, substituted_full)
  assert_eq(sub_before, "~/repos/")
  assert_eq(sub_root, "myproject")
  assert_eq(sub_after, "/src")
}

///|
test "substitutions on full path: multiple non-spanning substitutions" {
  let (raw_before, raw_root, raw_after) = build_repo_root_parts(
    "/home/user/Documents/myrepo/src/lib", "/home/user/Documents/myrepo", "/home/user",
    "~",
  )
  let subs : Array[(String, String)] = [
    ("Documents", "📁"),
    ("myrepo", "🔧"),
    ("src", "s"),
  ]

  let full = raw_before + raw_root + raw_after
  let substituted_full = apply_substitutions(full, subs)
  let sub_before = apply_substitutions(raw_before, subs)
  let sub_root = apply_substitutions(raw_root, subs)
  let sub_after = apply_substitutions(raw_after, subs)

  assert_eq(sub_before + sub_root + sub_after, substituted_full)
  assert_eq(sub_before, "~/📁/")
  assert_eq(sub_root, "🔧")
  assert_eq(sub_after, "/s/lib")
}
