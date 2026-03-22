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

  remove_dir_recursive(path)
}

///|
async test "detect_state: rebase-merge" {
  let path = "/tmp/moonship-test-git-state-rebase"
  setup_git_dir(path)
  @fs.create_dir(path + "/.git/rebase-merge") |> ignore

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "REBASING")

  remove_dir_recursive(path)
}

///|
async test "detect_state: rebase-apply" {
  let path = "/tmp/moonship-test-git-state-rebase-apply"
  setup_git_dir(path)
  @fs.create_dir(path + "/.git/rebase-apply") |> ignore

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "REBASING")

  remove_dir_recursive(path)
}

///|
async test "detect_state: MERGE_HEAD" {
  let path = "/tmp/moonship-test-git-state-merge"
  setup_git_dir(path)
  @fs.write_string_to_file(path + "/.git/MERGE_HEAD", "")

  assert_eq(detect_state(path + "/.git", GitStateModule::default()), "MERGING")

  remove_dir_recursive(path)
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

  remove_dir_recursive(path)
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

  remove_dir_recursive(path)
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

  remove_dir_recursive(path)
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

  remove_dir_recursive(path)
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
  remove_dir_recursive(path)
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.create_dir(path + "/.git") catch {
    _ => ()
  }
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
