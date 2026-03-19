///|
test "name" {
  let m : &@ms.PromptModule = GitBranchModule::new()
  assert_eq(m.name(), "git_branch")
}

///|
test "normal branch" {
  let git_info = @git.GitInfo::new(repo_root="/repo", branch="main")
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
}

///|
test "detached HEAD with hash" {
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="",
    is_detached=true,
    commit_hash="abc1234",
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("abc1234"))
}

///|
test "detached HEAD without hash returns None" {
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="",
    is_detached=true,
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "no git info returns None" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m : &@ms.PromptModule = GitBranchModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "disabled returns None" {
  let config = @config.Config::from_toml(
    (
      #|[git_branch]
      #|disabled = true
      #|
    ),
  )
  let git_info = @git.GitInfo::new(repo_root="/repo", branch="main")
  let ctx = @context.Context::new(cwd="/repo", config~, git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  assert_true(m.execute(ctx) is None)
}

///|
test "branch at truncation boundary" {
  // 20 chars exactly — should not truncate
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="12345678901234567890",
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("12345678901234567890"))
  assert_false(rendered.contains("…"))
}

///|
test "branch one over truncation boundary" {
  // 21 chars — should truncate
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="123456789012345678901",
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("…"))
}

///|
test "long branch truncated" {
  let git_info = @git.GitInfo::new(
    repo_root="/repo",
    branch="feature/very-long-branch-name-that-exceeds-limit",
  )
  let ctx = @context.Context::new(cwd="/repo", git_info=Some(git_info))
  let m : &@ms.PromptModule = GitBranchModule::new()

  guard m.execute(ctx) is Some(out) else { fail("expected output") }

  let rendered = out.render()
  assert_true(rendered.contains("…"))
}
