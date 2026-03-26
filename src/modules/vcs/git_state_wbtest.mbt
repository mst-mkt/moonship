///|
async test "name" {
  let m : &@ms.PromptModule = GitStateModule::default()
  assert_eq(m.name(), "git_state")
}

// --- detect_state ---

///|
async test "detect_state: no state files returns empty" {
  let path = "/tmp/moonship-test-git-state-clean"
  setup_git_dir(path)

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: rebase-merge" {
  let path = "/tmp/moonship-test-git-state-rebase"
  setup_git_dir(path)
  @fs.create_dir(path + "/.git/rebase-merge") |> ignore

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "REBASING")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: rebase-apply (am)" {
  let path = "/tmp/moonship-test-git-state-rebase-apply"
  setup_git_dir(path)
  @fs.create_dir(path + "/.git/rebase-apply") |> ignore

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "AM")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: rebase-apply with next (am_or_rebase)" {
  let path = "/tmp/moonship-test-git-state-am-rebase"
  setup_git_dir(path)
  @fs.create_dir(path + "/.git/rebase-apply") |> ignore
  @fs.write_string_to_file(path + "/.git/rebase-apply/next", "1")

  assert_eq(
    detect_state(path + "/.git", GitStateModule::default()),
    "AM/REBASE",
  )

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: MERGE_HEAD" {
  let path = "/tmp/moonship-test-git-state-merge"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/MERGE_HEAD", "")

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "MERGING")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: CHERRY_PICK_HEAD" {
  let path = "/tmp/moonship-test-git-state-cherry"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/CHERRY_PICK_HEAD", "")

  assert_eq(
    detect_state(path + "/.git", GitStateModule::default()),
    "CHERRY-PICKING",
  )

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: REVERT_HEAD" {
  let path = "/tmp/moonship-test-git-state-revert"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/REVERT_HEAD", "")

  assert_eq(
    detect_state(path + "/.git", GitStateModule::default()),
    "REVERTING",
  )

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: BISECT_LOG" {
  let path = "/tmp/moonship-test-git-state-bisect"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/BISECT_LOG", "")

  assert_eq(
    detect_state(path + "/.git", GitStateModule::default()),
    "BISECTING",
  )

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_state: custom labels" {
  let path = "/tmp/moonship-test-git-state-custom"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/MERGE_HEAD", "")

  let config = @config.Config::from_toml(
    (
      #|[git_state]
      #|merge = "マージ中"
    ),
  )
  let m = GitStateModule::from_config(config)

  assert_eq(detect_state(path + "/.git", m), "マージ中")

  @test_util.remove_dir_recursive(path)
}

// --- execute ---

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[git_state]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = GitStateModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: not in git repo returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = GitStateModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

// --- test helpers ---

///|
fn setup_git_dir(path : String) -> Unit {
  @test_util.remove_dir_recursive(path)
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.create_dir(path + "/.git") catch {
    _ => ()
  }
}
