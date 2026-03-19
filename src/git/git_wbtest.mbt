///|
test "extract_branch_name: strips refs/heads/" {
  assert_eq(extract_branch_name("refs/heads/main"), "main")
  assert_eq(extract_branch_name("refs/heads/feature/foo"), "feature/foo")
}

///|
test "extract_branch_name: no prefix" {
  assert_eq(extract_branch_name("main"), "main")
}

///|
test "extract_branch_name: empty" {
  assert_eq(extract_branch_name(""), "")
}

///|
test "parse_ahead_behind_output: valid" {
  assert_eq(parse_ahead_behind_output("3\t1"), (3, 1))
  assert_eq(parse_ahead_behind_output("0\t0"), (0, 0))
}

///|
test "parse_ahead_behind_output: invalid" {
  assert_eq(parse_ahead_behind_output(""), (0, 0))
  assert_eq(parse_ahead_behind_output("abc"), (0, 0))
}

///|
test "parse_ahead_behind_output: large numbers" {
  assert_eq(parse_ahead_behind_output("100\t200"), (100, 200))
}

///|
test "count_status: empty" {
  assert_eq(count_status([]), (0, 0, 0))
}

///|
test "count_status: mixed" {
  let flags = [
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_MODIFIED),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_MODIFIED),
  ]
  assert_eq(count_status(flags), (2, 1, 1))
}

///|
test "GitInfo::new defaults" {
  let info = GitInfo::new(repo_root="/repo", branch="main")
  assert_eq(info.is_detached, false)
  assert_eq(info.commit_hash, "")
  assert_eq(info.staged, 0)
  assert_eq(info.modified, 0)
  assert_eq(info.untracked, 0)
  assert_eq(info.ahead, 0)
  assert_eq(info.behind, 0)
}

///|
test "GitInfo JSON round-trip: all fields" {
  let info = GitInfo::new(
    repo_root="/home/user/project",
    branch="feature/test",
    is_detached=true,
    commit_hash="abc1234",
    staged=2,
    modified=3,
    untracked=1,
    ahead=5,
    behind=2,
  )

  let json = info.to_json()
  let restored : GitInfo = @json.from_json(json)
  assert_eq(restored, info)
}

///|
test "GitInfo JSON round-trip: defaults" {
  let info = GitInfo::new(repo_root="/repo", branch="main")

  let json = info.to_json()
  let restored : GitInfo = @json.from_json(json)
  assert_eq(restored, info)
}
