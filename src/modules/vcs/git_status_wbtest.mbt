///|
async test "name" {
  let m : &@ms.PromptModule = GitStatusModule::default()
  assert_eq(m.name(), "git_status")
}

// --- build_status_string unit tests ---

///|
async test "build_status_string: all types" {
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
async test "build_status_string: all zero" {
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
async test "build_status_string: count=1 symbol only" {
  assert_eq(build_status_string([(1, "+")]), "+")
}

///|
async test "build_status_string: count>1 shows count" {
  assert_eq(build_status_string([(5, "+")]), "+5")
}

// --- render_status unit tests ---

///|
let empty_git_status : @git.GitStatus = {
  staged: 0,
  modified: 0,
  untracked: 0,
  deleted: 0,
  conflicted: 0,
  renamed: 0,
  typechanged: 0,
  stashed: 0,
}

///|
async test "render_status: staged only" {
  let m = GitStatusModule::default()
  let status = { ..empty_git_status, staged: 1 }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("+"))
  assert_false(rendered.contains("!"))
}

///|
async test "render_status: modified only" {
  let m = GitStatusModule::default()
  let status = { ..empty_git_status, modified: 1 }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("!"))
}

///|
async test "render_status: all types present" {
  let m = GitStatusModule::default()
  let status = { ..empty_git_status, staged: 2, modified: 3, untracked: 1 }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("+"))
  assert_true(rendered.contains("!"))
  assert_true(rendered.contains("?"))
}

///|
async test "render_status: deleted only" {
  let m = GitStatusModule::default()
  let status = { ..empty_git_status, deleted: 1 }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("✘"))
}

///|
async test "render_status: all zero returns Skipped" {
  let m = GitStatusModule::default()
  assert_true(m.render_status(empty_git_status, 0, 0) is Skipped("no changes"))
}

///|
async test "render_status: custom symbols" {
  let config = @config.Config::from_toml(
    (
      #|[git_status]
      #|staged = "S"
      #|modified = "M"
      #|untracked = "U"
      #|deleted = "D"
    ),
  )
  let m = GitStatusModule::from_config(config)
  let status = {
    ..empty_git_status,
    staged: 1,
    modified: 1,
    untracked: 1,
    deleted: 1,
  }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("S"))
  assert_true(rendered.contains("M"))
  assert_true(rendered.contains("U"))
  assert_true(rendered.contains("D"))
}

///|
async test "render_status: ahead behind" {
  let m = GitStatusModule::default()
  guard m.render_status(empty_git_status, 3, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("⇡"))
}

///|
async test "render_status: diverged" {
  let m = GitStatusModule::default()
  guard m.render_status(empty_git_status, 2, 1) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("⇕"))
}

///|
async test "render_status: stashed" {
  let m = GitStatusModule::default()
  let status = { ..empty_git_status, stashed: 1 }
  guard m.render_status(status, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("$"))
}

///|
test "parse_ahead_behind: valid" {
  assert_eq(parse_ahead_behind("3\t5"), (5, 3))
}

///|
test "parse_ahead_behind: empty" {
  assert_eq(parse_ahead_behind(""), (0, 0))
}

///|
test "parse_ahead_behind: zero" {
  assert_eq(parse_ahead_behind("0\t0"), (0, 0))
}

///|
test "build_ahead_behind: ahead only" {
  assert_eq(build_ahead_behind(3, 0, "⇡", "⇣", "", "⇕"), "⇡")
}

///|
test "build_ahead_behind: behind only" {
  assert_eq(build_ahead_behind(0, 2, "⇡", "⇣", "", "⇕"), "⇣")
}

///|
test "build_ahead_behind: diverged" {
  assert_eq(build_ahead_behind(1, 1, "⇡", "⇣", "", "⇕"), "⇕")
}

///|
test "build_ahead_behind: up to date with symbol" {
  assert_eq(build_ahead_behind(0, 0, "⇡", "⇣", "✓", "⇕"), "✓")
}

///|
test "build_ahead_behind: up to date no symbol" {
  assert_eq(build_ahead_behind(0, 0, "⇡", "⇣", "", "⇕"), "")
}

// --- execute integration tests ---

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[git_status]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitStatusModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: not in git repo returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitStatusModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: clean repo returns Skipped no changes" {
  let path = "/tmp/moonship-test-git-status-clean"
  let repo = create_test_repo(path)

  let ctx = @context.Context::new(cwd=path)
  let m = GitStatusModule::default()
  assert_true(m.execute(ctx) is Skipped("no changes"))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

///|
async test "execute: modified file returns Output with modified symbol" {
  let path = "/tmp/moonship-test-git-status-dirty"
  let repo = create_test_repo(path)

  @fs.write_string_to_file(path + "/README.md", "modified content")

  let ctx = @context.Context::new(cwd=path)
  let m = GitStatusModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }
  assert_true(out.render().contains("!"))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

///|
async test "execute: untracked file returns Output with untracked symbol" {
  let path = "/tmp/moonship-test-git-status-untracked"
  let repo = create_test_repo(path)

  @fs.write_string_to_file(path + "/newfile.txt", "new")

  let ctx = @context.Context::new(cwd=path)
  let m = GitStatusModule::default()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }
  assert_true(out.render().contains("?"))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

// --- edge cases ---

///|
test "format_count: zero count" {
  assert_eq(format_count(0, "+"), "")
}

///|
test "format_count: count of 1" {
  assert_eq(format_count(1, "+"), "+")
}

///|
test "format_count: count greater than 1" {
  assert_eq(format_count(5, "+"), "+5")
}

///|
test "format_count: empty symbol" {
  assert_eq(format_count(3, ""), "3")
}

///|
test "build_status_string: all zeros" {
  assert_eq(build_status_string([(0, "+"), (0, "!"), (0, "?")]), "")
}

///|
test "build_ahead_behind: both zero no up_to_date symbol" {
  assert_eq(build_ahead_behind(0, 0, "⇡", "⇣", "", "⇕"), "")
}

///|
test "build_ahead_behind: both zero with up_to_date symbol" {
  assert_eq(build_ahead_behind(0, 0, "⇡", "⇣", "✓", "⇕"), "✓")
}

///|
test "parse_ahead_behind: empty string" {
  assert_eq(parse_ahead_behind(""), (0, 0))
}

///|
test "parse_ahead_behind: malformed input" {
  assert_eq(parse_ahead_behind("not-valid"), (0, 0))
}

///|
test "parse_ahead_behind: tab separated" {
  assert_eq(parse_ahead_behind("3\t5"), (5, 3))
}

// --- test helpers ---

///|
fn create_test_repo(path : String) -> @libgit2.Repository raise {
  @test_util.remove_dir_recursive(path)

  @libgit2.git_init() |> ignore

  let repo = @libgit2.Repository::init(path).unwrap()

  @fs.write_string_to_file(path + "/README.md", "hello")

  let index = repo.index().unwrap()
  index.add("README.md") |> ignore
  let tree_oid = index.write_tree().unwrap()
  index.write() |> ignore
  index.close()

  let sig = @libgit2.Signature::now("test", "test@test.com").unwrap()
  repo.commit("initial", sig, sig, tree_oid) |> ignore
  sig.close()

  repo
}

///|
fn cleanup_test_repo(repo : @libgit2.Repository, path : String) -> Unit {
  repo.close()
  @libgit2.git_shutdown()
  @test_util.remove_dir_recursive(path)
}
