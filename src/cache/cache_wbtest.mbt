///|
test "hash_path: different paths produce different hashes" {
  let h1 = hash_path("/home/user/project-a")
  let h2 = hash_path("/home/user/project-b")
  assert_true(h1 != h2)
}

///|
test "hash_path: non-empty for empty input" {
  let h = hash_path("")
  assert_true(not(h.is_empty()))
}

///|
test "cache_file_path: contains dir and ends with .json" {
  let path = cache_file_path("/tmp/test", "/repo")
  assert_true(path.has_prefix("/tmp/test/"))
  assert_true(path.has_suffix(".json"))
}

///|
test "cache_dir: ends with /cache" {
  let dir = cache_dir()
  assert_true(not(dir.is_empty()))
  assert_true(dir.has_suffix("/cache"))
}

///|
test "write_cache and read_cache: round-trip" {
  let info = @git.GitInfo::new(
    repo_root="/tmp/test-repo",
    branch="main",
    staged=1,
    modified=2,
  )

  write_cache("/tmp/test-repo", info)
  let restored = read_cache("/tmp/test-repo", 60000)
  assert_eq(restored, Some(info))

  // cleanup
  clear_cache()
}

///|
test "read_cache: returns None for missing cache" {
  let result = read_cache("/nonexistent/repo", 5000)
  assert_eq(result, None)
}
