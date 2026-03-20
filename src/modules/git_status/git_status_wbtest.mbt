///|
async test "name" {
  let m : &@ms.PromptModule = GitStatusModule::new()
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
  assert_eq(result, "⇡+!?")
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
async test "build_status_string: count>1 symbol only" {
  assert_eq(build_status_string([(5, "+")]), "+")
}

// --- render_status unit tests ---

///|
async test "render_status: staged only" {
  let m = GitStatusModule::new()
  guard m.render_status(1, 0, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("+"))
  assert_false(rendered.contains("!"))
  assert_false(rendered.contains("?"))
}

///|
async test "render_status: modified only" {
  let m = GitStatusModule::new()
  guard m.render_status(0, 1, 0, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_false(rendered.contains("+"))
  assert_true(rendered.contains("!"))
}

///|
async test "render_status: all types present" {
  let m = GitStatusModule::new()
  guard m.render_status(2, 3, 1, 0) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("+"))
  assert_true(rendered.contains("!"))
  assert_true(rendered.contains("?"))
}

///|
async test "render_status: deleted only" {
  let m = GitStatusModule::new()
  guard m.render_status(0, 0, 0, 1) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("✘"))
  assert_false(rendered.contains("+"))
}

///|
async test "render_status: all zero returns Skipped" {
  let m = GitStatusModule::new()
  assert_true(m.render_status(0, 0, 0, 0) is Skipped("no changes"))
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
  guard m.render_status(1, 1, 1, 1) is Output(out) else {
    fail("expected Output")
  }

  let rendered = out.render()
  assert_true(rendered.contains("S"))
  assert_true(rendered.contains("M"))
  assert_true(rendered.contains("U"))
  assert_true(rendered.contains("D"))
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
  let m = GitStatusModule::new()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "execute: clean repo returns Skipped no changes" {
  let path = "/tmp/moonship-test-git-status-clean"
  let repo = create_test_repo(path)

  let ctx = @context.Context::new(cwd=path)
  let m = GitStatusModule::new()
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
  let m = GitStatusModule::new()
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
  let m = GitStatusModule::new()
  guard m.execute(ctx) is Output(out) else { fail("expected Output") }
  assert_true(out.render().contains("?"))

  ctx.close_repo()
  cleanup_test_repo(repo, path)
}

// --- test helpers ---

///|
fn create_test_repo(path : String) -> @libgit2.Repository raise {
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
