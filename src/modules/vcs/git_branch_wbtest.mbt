///|
async test "name" {
  let m : &@ms.PromptModule = GitBranchModule::default()
  assert_eq(m.name(), "git_branch")
}

// --- render_branch unit tests ---

///|
async test "render_branch: normal branch" {
  let m = GitBranchModule::default()
  guard m.render_branch("main", false, "abc1234", "", "") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
  assert_true(rendered.contains(";35m"))
}

///|
async test "render_branch: detached HEAD shows commit hash" {
  let m = GitBranchModule::default()
  guard m.render_branch("", true, "abc1234", "", "") is Output(out) else {
    fail("expected Output")
  }

  assert_true(out.render().contains("(abc1234)"))
}

///|
async test "render_branch: detached HEAD with empty hash returns Skipped" {
  let m = GitBranchModule::default()
  assert_true(m.render_branch("", true, "", "", "") is Skipped(_))
}

///|
async test "render_branch: truncation" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|truncation_length = 4
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("feature/long-branch-name", false, "", "", "")
    is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("feat"))
  assert_true(rendered.contains("…"))
  assert_false(rendered.contains("long-branch-name"))
}

///|
async test "render_branch: custom symbol" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|symbol = "BR "
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "", "") is Output(out) else {
    fail("expected Output")
  }

  assert_true(out.render().contains("BR"))
}

///|
async test "render_branch: custom truncation_symbol" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|truncation_length = 4
      #|truncation_symbol = "..."
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("feature/long", false, "", "", "") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("feat"))
  assert_true(rendered.contains("..."))
}

///|
async test "render_branch: only_attached skips detached" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|only_attached = true
    ),
  )
  let m = GitBranchModule::from_config(config)
  assert_true(m.render_branch("", true, "abc1234", "", "") is Skipped(_))
}

///|
async test "render_branch: only_attached allows normal branch" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|only_attached = true
    ),
  )
  let m = GitBranchModule::from_config(config)
  assert_true(m.render_branch("main", false, "", "", "") is Output(_))
}

///|
async test "render_branch: ignore_branches hides matching" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|ignore_branches = "main,master"
    ),
  )
  let m = GitBranchModule::from_config(config)
  assert_true(m.render_branch("main", false, "", "", "") is Skipped(_))
}

///|
async test "render_branch: ignore_branches allows non-matching" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|ignore_branches = "main,master"
    ),
  )
  let m = GitBranchModule::from_config(config)
  assert_true(m.render_branch("feature/test", false, "", "", "") is Output(_))
}

///|
async test "parse_string_list: basic" {
  assert_eq(parse_string_list("a,b,c"), ["a", "b", "c"])
}

///|
async test "parse_string_list: empty" {
  assert_eq(parse_string_list(""), [])
}

// --- remote branch tests ---

///|
async test "render_branch: remote_branch shown when differs from local" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|format = "[$branch(:$remote_branch)]($style)"
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "origin", "upstream-main")
    is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
  assert_true(rendered.contains("upstream-main"))
}

///|
async test "render_branch: remote_branch hidden when same as local" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|format = "[$branch(:$remote_branch)]($style)"
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "origin", "main") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
  assert_false(rendered.contains(":main"))
}

///|
async test "render_branch: always_show_remote forces remote display" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|always_show_remote = true
      #|format = "[$branch(:$remote_branch)]($style)"
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "origin", "main") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains(":main"))
}

///|
async test "render_branch: no remote tracking" {
  let m = GitBranchModule::default()
  guard m.render_branch("feature", false, "", "", "") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("feature"))
}

///|
async test "render_branch: remote_name in vars" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|always_show_remote = true
      #|format = "[$remote_name/$remote_branch]($style)"
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "origin", "main") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("origin"))
}

///|
async test "render_branch: always_show_remote with no tracking" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|always_show_remote = true
      #|format = "[$branch(:$remote_branch)]($style)"
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("main", false, "", "", "") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
}

// --- execute integration tests ---

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitBranchModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: not in git repo returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitBranchModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: real repo returns Output with branch" {
  let path = "/tmp/moonship-test-git-branch"
  let repo = create_test_repo(path)

  let ctx = @context.Context::new(cwd=path)
  let m = GitBranchModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.length() > 0)
  assert_true(rendered.contains(";35m"))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

// --- edge cases ---

///|
async test "render_branch: detached HEAD shows short hash" {
  let m = GitBranchModule::default()
  guard m.render_branch("", true, "abc1234def5678", "", "") is Output(out) else {
    fail("expected Output")
  }
  let rendered = out.render()
  assert_true(rendered.contains("abc1234"))
}

///|
async test "render_branch: very long branch name truncated" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|truncation_length = 10
    ),
  )
  let m = GitBranchModule::from_config(config)
  guard m.render_branch("feature/very-long-branch-name-here", false, "", "", "")
    is Output(out) else {
    fail("expected Output")
  }
  let rendered = out.render()
  assert_true(rendered.contains("…"))
}

// --- test helpers ---
