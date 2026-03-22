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
test "write_prompt and read_prompt: round-trip" {
  write_prompt("/tmp/test-cwd", 0, "test-prompt-output")
  let restored = read_prompt("/tmp/test-cwd", 0, 60000)
  assert_eq(restored, Some("test-prompt-output"))

  clear_cache()
}

///|
test "read_prompt: status mismatch returns None" {
  write_prompt("/tmp/test-cwd", 0, "prompt-for-status-0")
  let result = read_prompt("/tmp/test-cwd", 1, 60000)
  assert_eq(result, None)

  clear_cache()
}

///|
test "read_prompt: returns None for missing cache" {
  let result = read_prompt("/nonexistent/cwd", 0, 5000)
  assert_eq(result, None)
}

///|
test "hash_path: same path produces same hash" {
  let h1 = hash_path("/home/user/project")
  let h2 = hash_path("/home/user/project")
  assert_eq(h1, h2)
}

///|
test "hash_path: empty path does not crash" {
  let h = hash_path("")
  assert_eq(h, "5381")
}

///|
test "read_prompt: expired cache returns None" {
  write_prompt("/tmp/test-cwd-expired", 0, "expired-prompt")

  // TTL of 0 means immediately expired
  let result = read_prompt("/tmp/test-cwd-expired", 0, 0)
  assert_eq(result, None)

  clear_cache()
}

///|
test "read_prompt: wrong version returns None" {
  // Write a cache entry manually with wrong version
  let dir = cache_dir()
  ensure_dir(dir)
  let path = cache_file_path(dir, "/tmp/test-cwd-wrong-ver")
  let json = "{\"v\":999,\"ts\":9999999999999,\"status\":0,\"prompt\":\"stale\"}"
  @fs.write_string_to_file(path, json) catch {
    _ => ()
  }

  let result = read_prompt("/tmp/test-cwd-wrong-ver", 0, 60000)
  assert_eq(result, None)

  clear_cache()
}

///|
test "write_prompt and read_prompt: multiple cwds independent" {
  write_prompt("/tmp/test-cwd-a", 0, "prompt-a")
  write_prompt("/tmp/test-cwd-b", 0, "prompt-b")

  assert_eq(read_prompt("/tmp/test-cwd-a", 0, 60000), Some("prompt-a"))
  assert_eq(read_prompt("/tmp/test-cwd-b", 0, 60000), Some("prompt-b"))

  clear_cache()
}
