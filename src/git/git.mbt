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
pub fn RepoHandle::get_status(self : RepoHandle) -> (Int, Int, Int, Int) {
  count_status(self.repo.status_flags())
}

///|
fn find_repo_root(cwd : String) -> String? {
  loop (cwd, 0) {
    (dir, i) =>
      if i >= 50 {
        break None
      } else if @fs.path_exists(dir + "/.git") {
        break Some(dir)
      } else {
        match last_slash(dir) {
          Some(idx) =>
            if idx == 0 {
              break None
            } else {
              continue (dir[:idx].to_string(), i + 1)
            }
          None => break None
        }
      }
  }
}

///|
fn last_slash(s : String) -> Int? {
  let init : (Int?, Int) = (None, 0)

  s
  .iter()
  .fold(init~, fn(acc, ch) {
    let (result, i) = acc
    (if ch == '/' { Some(i) } else { result }, i + 1)
  }).0
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
fn count_status(flags : Array[@libgit2.StatusFlags]) -> (Int, Int, Int, Int) {
  flags
  .iter()
  .fold(init=(0, 0, 0, 0), fn(acc, f) {
    let (s, m, u, d) = acc
    (
      s + Bool::to_int(f.is_staged()),
      m + Bool::to_int(f.is_modified()),
      u + Bool::to_int(f.is_new()),
      d + Bool::to_int(f.is_deleted()),
    )
  })
}
