///|
async test "name" {
  let m : &@ms.PromptModule = GitCommitModule::default()
  assert_eq(m.name(), "git_commit")
}

// --- execute ---

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[git_commit]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GitCommitModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: not in git repo returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitCommitModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: only_detached skips attached branch" {
  let path = "/tmp/moonship-test-git-commit-attached"
  let repo = create_test_repo(path)

  let ctx = @context.Context::new(cwd=path)
  let m = GitCommitModule::default()
  assert_true(m.execute(ctx) is Skipped(_))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

///|
async test "execute: only_detached=false shows hash for attached" {
  let path = "/tmp/moonship-test-git-commit-show-all"
  let repo = create_test_repo(path)

  let config = @config.Config::from_toml(
    (
      #|[git_commit]
      #|only_detached = false
    ),
  )
  let ctx = @context.Context::new(cwd=path, config~)
  let m = GitCommitModule::from_config(config)
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }

  let rendered = out.render()
  assert_true(rendered.length() > 0)

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

// --- test helpers ---
