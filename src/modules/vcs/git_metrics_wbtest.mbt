///|
async test "name" {
  let m : &@ms.PromptModule = GitMetricsModule::default()
  assert_eq(m.name(), "git_metrics")
}

///|
async test "execute: disabled by default" {
  let m = GitMetricsModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_shortstat: insertions and deletions" {
  let (added, deleted) = parse_shortstat(
    " 3 files changed, 10 insertions(+), 5 deletions(-)",
  )
  assert_eq(added, 10)
  assert_eq(deleted, 5)
}

///|
test "parse_shortstat: insertions only" {
  let (added, deleted) = parse_shortstat(" 1 file changed, 3 insertions(+)")
  assert_eq(added, 3)
  assert_eq(deleted, 0)
}

///|
test "parse_shortstat: deletions only" {
  let (added, deleted) = parse_shortstat(" 2 files changed, 7 deletions(-)")
  assert_eq(added, 0)
  assert_eq(deleted, 7)
}

///|
test "parse_shortstat: empty" {
  let (added, deleted) = parse_shortstat("")
  assert_eq(added, 0)
  assert_eq(deleted, 0)
}

///|
test "extract_leading_number: standard" {
  assert_eq(extract_leading_number(" 10 insertions(+)"), 10)
}

///|
test "extract_leading_number: no number" {
  assert_eq(extract_leading_number("no numbers"), 0)
}
