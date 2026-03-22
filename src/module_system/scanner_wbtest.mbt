// --- char_at ---

///|
test "char_at: basic character access" {
  assert_eq(char_at("hello", 0), 'h')
  assert_eq(char_at("hello", 4), 'o')
}

///|
test "char_at: special characters" {
  assert_eq(char_at("a\tb", 1), '\t')
  assert_eq(char_at("a\nb", 1), '\n')
}

// --- unescape ---

///|
test "unescape: newline" {
  assert_eq(unescape('n'), "\n")
}

///|
test "unescape: tab" {
  assert_eq(unescape('t'), "\t")
}

///|
test "unescape: other chars passthrough" {
  assert_eq(unescape('a'), "a")
  assert_eq(unescape('\\'), "\\")
  assert_eq(unescape('$'), "$")
}

// --- scan_while ---

///|
test "scan_while: empty string" {
  let result = scan_while("", 0, fn(_c) { true })
  assert_eq(result, 0)
}

///|
test "scan_while: start past end" {
  let result = scan_while("abc", 10, fn(_c) { true })
  assert_eq(result, 10)
}

///|
test "scan_while: predicate always true" {
  let result = scan_while("abcde", 0, fn(_c) { true })
  assert_eq(result, 5)
}

///|
test "scan_while: predicate always false" {
  let result = scan_while("abcde", 0, fn(_c) { false })
  assert_eq(result, 0)
}

///|
test "scan_while: stops at correct position" {
  let result = scan_while("abc123", 0, fn(c) { c >= 'a' && c <= 'z' })
  assert_eq(result, 3)
}

///|
test "scan_while: starts from middle" {
  let result = scan_while("abc123def", 3, fn(c) { c >= '0' && c <= '9' })
  assert_eq(result, 6)
}

// --- scan_ident ---

///|
test "scan_ident: valid letters only" {
  let (name, end) = scan_ident("hello world", 0)
  assert_eq(name, "hello")
  assert_eq(end, 5)
}

///|
test "scan_ident: letters digits underscores" {
  let (name, end) = scan_ident("a_b_1!", 0)
  assert_eq(name, "a_b_1")
  assert_eq(end, 5)
}

///|
test "scan_ident: starts with digit" {
  let (name, end) = scan_ident("123abc", 0)
  assert_eq(name, "123abc")
  assert_eq(end, 6)
}

///|
test "scan_ident: empty result on non-ident char" {
  let (name, end) = scan_ident("!abc", 0)
  assert_eq(name, "")
  assert_eq(end, 0)
}

///|
test "scan_ident: starts from offset" {
  let (name, end) = scan_ident("$hello", 1)
  assert_eq(name, "hello")
  assert_eq(end, 6)
}

///|
test "scan_ident: empty string" {
  let (name, end) = scan_ident("", 0)
  assert_eq(name, "")
  assert_eq(end, 0)
}

///|
test "scan_ident: underscore only" {
  let (name, end) = scan_ident("_", 0)
  assert_eq(name, "_")
  assert_eq(end, 1)
}

// --- find_matching ---

///|
test "find_matching: simple parens" {
  let result = find_matching("(abc)", 0, '(', ')')
  assert_eq(result, Some(4))
}

///|
test "find_matching: nested parens" {
  let result = find_matching("((abc))", 0, '(', ')')
  assert_eq(result, Some(6))
}

///|
test "find_matching: escaped close" {
  let result = find_matching("(a\\)b)", 0, '(', ')')
  assert_eq(result, Some(5))
}

///|
test "find_matching: unmatched open" {
  let result = find_matching("(abc", 0, '(', ')')
  assert_eq(result, None)
}

///|
test "find_matching: empty content" {
  let result = find_matching("()", 0, '(', ')')
  assert_eq(result, Some(1))
}

///|
test "find_matching: multiple nesting levels" {
  let result = find_matching("(a(b(c))d)", 0, '(', ')')
  assert_eq(result, Some(9))
}

///|
test "find_matching: square brackets" {
  let result = find_matching("[inner]", 0, '[', ']')
  assert_eq(result, Some(6))
}

///|
test "find_matching: nested square brackets" {
  let result = find_matching("[[x]]", 0, '[', ']')
  assert_eq(result, Some(4))
}

///|
test "find_matching: escape at end of string" {
  // String is "(a\\" - open paren, 'a', backslash, backslash
  // The backslash escapes the next char, so the close paren is missing
  let result = find_matching("(a\\", 0, '(', ')')
  assert_eq(result, None)
}
