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
pub fn RepoHandle::is_bare(self : RepoHandle) -> Bool {
  // Normal repos: repo.path() ends with "/.git/" or "/.git"
  // Bare repos: repo.path() is the repo root itself (no .git suffix)
  let repo_path = self.repo.path()
  not(repo_path.has_suffix("/.git/") || repo_path.has_suffix("/.git"))
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
pub fn RepoHandle::get_remote_branch(
  self : RepoHandle,
  branch : String,
) -> (String, String) {
  guard not(branch.is_empty()) else { return ("", "") }

  let remote_name = self.repo
    .config_get("branch.\{branch}.remote")
    .unwrap_or("")

  let merge_ref = self.repo
    .config_get("branch.\{branch}.merge")
    .unwrap_or("")

  let refs_heads = "refs/heads/"
  let remote_branch = if merge_ref.has_prefix(refs_heads) {
    merge_ref[refs_heads.length():].to_string()
  } else {
    merge_ref
  }

  (remote_name, remote_branch)
}

///|
pub(all) struct GitStatus {
  staged : Int
  modified : Int
  untracked : Int
  deleted : Int
  conflicted : Int
  renamed : Int
  typechanged : Int
  stashed : Int
} derive(Show, Eq)

///|
pub fn RepoHandle::get_status(self : RepoHandle) -> GitStatus {
  let base = count_status(self.repo.status_flags())
  let stashed = if has_stash(self.root) { 1 } else { 0 }

  { ..base, stashed }
}

///|
fn find_repo_root(cwd : String) -> String? {
  loop (cwd, 0) {
    (dir, i) =>
      if i >= 50 {
        break None
      } else if @fs.path_exists("\{dir}/.git") {
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
fn has_stash(root : String) -> Bool {
  if @fs.path_exists("\{root}/.git/refs/stash") {
    return true
  }

  let packed_refs_path = "\{root}/.git/packed-refs"
  guard @fs.path_exists(packed_refs_path) else { return false }

  let content = @fs.read_file_to_string(packed_refs_path) catch { _ => return false }
  content.contains("refs/stash")
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
let git_status_index_renamed = 8

///|
let git_status_index_typechange = 16

///|
let git_status_wt_renamed = 2048

///|
let git_status_wt_typechange = 4096

///|
let git_status_conflicted = 32768

///|
fn count_status(flags : Array[@libgit2.StatusFlags]) -> GitStatus {
  flags
  .iter()
  .fold(
    init={
      staged: 0,
      modified: 0,
      untracked: 0,
      deleted: 0,
      conflicted: 0,
      renamed: 0,
      typechanged: 0,
      stashed: 0,
    },
    fn(acc, f) {
      let bits = f.flags
      {
        staged: acc.staged + Bool::to_int(f.is_staged()),
        modified: acc.modified + Bool::to_int(f.is_modified()),
        untracked: acc.untracked + Bool::to_int(f.is_new()),
        deleted: acc.deleted + Bool::to_int(f.is_deleted()),
        conflicted: acc.conflicted +
          Bool::to_int(bits.land(git_status_conflicted) != 0),
        renamed: acc.renamed +
          Bool::to_int(
            bits.land(git_status_index_renamed.lor(git_status_wt_renamed)) != 0,
          ),
        typechanged: acc.typechanged +
          Bool::to_int(
            bits.land(
              git_status_index_typechange.lor(git_status_wt_typechange),
            ) !=
            0,
          ),
        stashed: 0,
      }
    },
  )
}
