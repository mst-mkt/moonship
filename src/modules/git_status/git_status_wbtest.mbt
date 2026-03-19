///|
test "name" {
  let m : &@ms.PromptModule = GitStatusModule::new()
  assert_eq(m.name(), "git_status")
}

///|
test "build_status_string: all types" {
  let result = build_status_string([
    (1, "⇡"),
    (0, "⇣"),
    (2, "+"),
    (1, "!"),
    (3, "?"),
  ])
  assert_eq(result, "⇡+2!?3")
}

///|
test "build_status_string: all zero" {
  let result = build_status_string([
    (0, "⇡"),
    (0, "⇣"),
    (0, "+"),
    (0, "!"),
    (0, "?"),
  ])
  assert_eq(result, "")
}

///|
test "build_status_string: count=1 symbol only" {
  assert_eq(build_status_string([(1, "+")]), "+")
}

///|
test "build_status_string: count>1 symbol+number" {
  assert_eq(build_status_string([(5, "+")]), "+5")
}

///|
test "no git info returns None" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m : &@ms.PromptModule = GitStatusModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "clean repo returns None" {
  let git_info = @git.GitInfo::new(repo_root="/repo", branch="main")
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitStatusModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "dirty repo shows status" {
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="main",
    modified=2,
    untracked=1,
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitStatusModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("!2"))
  assert_true(rendered.contains("?"))
}

///|
test "ahead/behind displayed" {
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="main",
    ahead=3,
    behind=1,
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitStatusModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("⇡3"))
  assert_true(rendered.contains("⇣"))
}

///|
test "staged only" {
  let git_info = @git.GitInfo::new(repo_root="/repo", branch="main", staged=3)
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitStatusModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("+3"))
}

///|
test "disabled returns None" {
  let config = @config.Config::from_toml(
    (
      #|[git_status]
      #|disabled = true
      #|
    ),
  )
  let git_info = @git.GitInfo::new(repo_root="/repo", branch="main", modified=1)
  let ctx = @context.Context::new(cwd="/repo", config~, git_info=Some(git_info))
  let m : &@ms.PromptModule = GitStatusModule::new()

  assert_true(m.execute(ctx) is None)
}
