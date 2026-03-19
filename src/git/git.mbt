///|
pub struct RepoHandle {
  repo : @libgit2.Repository
  root : String
}

///|
pub fn open_repo(cwd : String) -> RepoHandle? {
  guard @libgit2.git_init() else { return None }

  let repo_root = find_repo_root(cwd).unwrap_or(cwd)
  guard @libgit2.Repository::open(repo_root) is Some(repo) else {
    @libgit2.git_shutdown()
    return None
  }

  Some({ repo, root: repo_root })
}

///|
pub fn RepoHandle::close(self : RepoHandle) -> Unit {
  self.repo.close()
  @libgit2.git_shutdown()
}

///|
pub fn RepoHandle::repo_root(self : RepoHandle) -> String {
  self.root
}

///|
pub fn RepoHandle::get_branch(self : RepoHandle) -> (String, Bool, String) {
  let (branch, is_detached) = match self.repo.head_name() {
    Some(name) => (extract_branch_name(name), false)
    None => ("", true)
  }

  let commit_hash = match self.repo.head_id() {
    Some(id) => if id.length() >= 7 { id[:7].to_string() } else { id }
    None => ""
  }

  (branch, is_detached, commit_hash)
}

///|
pub fn RepoHandle::get_status(self : RepoHandle) -> (Int, Int, Int) {
  count_status(self.repo.status_flags())
}

///|
fn find_repo_root(cwd : String) -> String? {
  let mut dir = cwd

  for i = 0; i < 50; i = i + 1 {
    if @fs.path_exists(dir + "/.git") {
      return Some(dir)
    }

    match last_slash(dir) {
      Some(idx) =>
        if idx == 0 {
          return None
        } else {
          dir = dir[:idx].to_string()
        }
      None => return None
    }
  }

  None
}

///|
fn last_slash(s : String) -> Int? {
  let mut result : Int? = None
  let mut i = 0

  for ch in s {
    if ch == '/' {
      result = Some(i)
    }
    i = i + 1
  }

  result
}

///|
fn extract_branch_name(head_ref : String) -> String {
  let prefix = "refs/heads/"

  if head_ref.has_prefix(prefix) {
    head_ref[prefix.length():].to_string()
  } else {
    head_ref
  }
}

///|
fn count_status(flags : Array[@libgit2.StatusFlags]) -> (Int, Int, Int) {
  flags
  .iter()
  .fold(init=(0, 0, 0), fn(acc, f) {
    let (s, m, u) = acc
    (
      s + Bool::to_int(f.is_staged()),
      m + Bool::to_int(f.is_modified()),
      u + Bool::to_int(f.is_new()),
    )
  })
}
