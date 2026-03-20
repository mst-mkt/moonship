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
test "count_status: empty" {
  assert_eq(count_status([]), (0, 0, 0, 0))
}

///|
test "count_status: mixed" {
  let flags = [
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_MODIFIED),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_NEW),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_MODIFIED),
  ]
  assert_eq(count_status(flags), (2, 1, 1, 0))
}

///|
test "count_status: with deleted" {
  let flags = [
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_WT_DELETED),
    @libgit2.StatusFlags::new(@libgit2.GIT_STATUS_INDEX_NEW),
  ]
  assert_eq(count_status(flags), (1, 0, 0, 1))
}

///|
test "last_slash: basic" {
  assert_eq(last_slash("/home/user"), Some(5))
  assert_eq(last_slash("/"), Some(0))
  assert_eq(last_slash("noslash"), None)
}

///|
test "find_repo_root: not found returns None" {
  assert_eq(find_repo_root("/nonexistent/path"), None)
}
