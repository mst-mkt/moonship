///|
async test "name" {
  let m : &@ms.PromptModule = GitBranchModule::default()
  assert_eq(m.name(), "git_branch")
}

// --- render_branch unit tests ---

///|
async test "render_branch: normal branch" {
  let m = GitBranchModule::default()
  guard m.render_branch("main", false, "abc1234") is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("main"))
  assert_true(rendered.contains(";35m"))
}

///|
async test "render_branch: detached HEAD shows commit hash" {
  let m = GitBranchModule::default()
  guard m.render_branch("", true, "abc1234") is Output(out) else {
    fail("expected Output")
  }

  assert_true(out.render().contains("(abc1234)"))
}

///|
async test "render_branch: detached HEAD with empty hash returns Skipped" {
  let m = GitBranchModule::default()
  assert_true(m.render_branch("", true, "") is Skipped(_))
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
  guard m.render_branch("feature/long-branch-name", false, "") is Output(out) else {
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
  guard m.render_branch("main", false, "") is Output(out) else {
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
  guard m.render_branch("feature/long", false, "") is Output(out) else {
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
  assert_true(m.render_branch("", true, "abc1234") is Skipped(_))
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
  assert_true(m.render_branch("main", false, "") is Output(_))
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
  assert_true(m.render_branch("main", false, "") is Skipped(_))
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
  assert_true(m.render_branch("feature/test", false, "") is Output(_))
}

///|
async test "parse_string_list: basic" {
  assert_eq(parse_string_list("a,b,c"), ["a", "b", "c"])
}

///|
async test "parse_string_list: empty" {
  assert_eq(parse_string_list(""), [])
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

// --- test helpers ---

///|
fn create_test_repo(path : String) -> @libgit2.Repository raise {
  // Clean up stale directory from previous failed runs
  remove_dir_recursive(path)

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
  remove_dir_recursive(path)
}

///|
fn remove_dir_recursive(path : String) -> Unit {
  if not(@fs.path_exists(path)) {
    return
  }

  let entries = @fs.read_dir(path) catch { _ => return }

  for entry in entries {
    let full = path + "/" + entry
    let is_dir = @fs.is_dir(full) catch { _ => false }

    if is_dir {
      remove_dir_recursive(full)
    } else {
      @fs.remove_file(full) catch {
        _ => ()
      }
    }
  }

  @fs.remove_dir(path) catch {
    _ => ()
  }
}
