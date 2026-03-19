///|
test "name" {
  let m : &@ms.PromptModule = GitBranchModule::new()
  assert_eq(m.name(), "git_branch")
}
