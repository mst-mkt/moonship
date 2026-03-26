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
let empty_status : GitStatus = {
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
test "count_status: empty" {
  assert_eq(count_status([]), empty_status)
}

///|
test "count_status: mixed" {
  let flags = [
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_MODIFIED),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_MODIFIED),
  ]
  let result = count_status(flags)
  assert_eq(result.staged, 2)
  assert_eq(result.modified, 1)
  assert_eq(result.untracked, 1)
  assert_eq(result.deleted, 0)
}

///|
test "count_status: with deleted" {
  let flags = [
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_DELETED),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_NEW),
  ]
  let result = count_status(flags)
  assert_eq(result.staged, 1)
  assert_eq(result.deleted, 1)
  assert_eq(result.untracked, 0)
}

///|
test "count_status: conflicted" {
  let flags = [@libgit2.StatusFlags::new(git_status_conflicted)]
  let result = count_status(flags)
  assert_eq(result.conflicted, 1)
}

///|
test "count_status: renamed" {
  let flags = [@libgit2.StatusFlags::new(git_status_index_renamed)]
  let result = count_status(flags)
  assert_eq(result.renamed, 1)
}

///|
test "last_slash: basic" {
  assert_eq(@exec.last_slash("/home/user"), Some(5))
  assert_eq(@exec.last_slash("/"), Some(0))
  assert_eq(@exec.last_slash("noslash"), None)
}

///|
test "find_repo_root: not found returns None" {
  assert_eq(find_repo_root("/nonexistent/path"), None)
}

// --- edge cases ---

///|
test "extract_branch_name: only prefix" {
  assert_eq(extract_branch_name("refs/heads/"), "")
}

///|
test "extract_branch_name: wrong prefix" {
  assert_eq(extract_branch_name("refs/tags/v1.0"), "refs/tags/v1.0")
}

///|
test "count_status: typechanged" {
  let flags = [@libgit2.StatusFlags::new(git_status_index_typechange)]
  let result = count_status(flags)
  assert_eq(result.typechanged, 1)
}

///|
test "count_status: worktree renamed" {
  let flags = [@libgit2.StatusFlags::new(git_status_wt_renamed)]
  let result = count_status(flags)
  assert_eq(result.renamed, 1)
}

///|
test "count_status: worktree typechanged" {
  let flags = [@libgit2.StatusFlags::new(git_status_wt_typechange)]
  let result = count_status(flags)
  assert_eq(result.typechanged, 1)
}

///|
test "count_status: combined flags" {
  let combined = git_status_index_renamed.lor(git_status_wt_renamed)
  let flags = [@libgit2.StatusFlags::new(combined)]
  let result = count_status(flags)
  assert_eq(result.renamed, 1)
}

///|
test "find_repo_root: empty string returns None" {
  assert_eq(find_repo_root(""), None)
}

///|
test "find_repo_root: root path returns None" {
  assert_eq(find_repo_root("/"), None)
}
