///|
test "replace home with ~" {
  assert_eq(format_path("/home/user/project", "/home/user", 3), "~/project")
}

///|
test "root path" {
  assert_eq(format_path("/", "", 3), "/")
}

///|
test "home exact match" {
  assert_eq(format_path("/home/user", "/home/user", 3), "~")
}

///|
test "deep path truncation" {
  assert_eq(format_path("/a/b/c/d/e", "", 3), "…/c/d/e")
}

///|
test "truncation_length=1" {
  assert_eq(format_path("/a/b/c/d/e", "", 1), "…/e")
}

///|
test "empty path" {
  assert_eq(format_path("", "", 3), "")
}

///|
test "no home replacement when home is empty" {
  assert_eq(format_path("/home/user/project", "", 3), "/home/user/project")
}

///|
test "split_path: removes empty segments" {
  assert_eq(split_path("/a//b/"), ["a", "b"])
}

///|
test "unicode path" {
  assert_eq(
    format_path("/home/user/プロジェクト/src", "/home/user", 3),
    "~/プロジェクト/src",
  )
}

///|
test "path with spaces" {
  assert_eq(
    format_path("/home/user/my project/src", "/home/user", 3),
    "~/my project/src",
  )
}

///|
test "exact truncation boundary" {
  assert_eq(format_path("/a/b/c", "", 3), "/a/b/c")
}

///|
test "one over truncation boundary" {
  assert_eq(format_path("/a/b/c/d", "", 3), "…/b/c/d")
}
