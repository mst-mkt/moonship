///|
pub(all) struct GitInfo {
  repo_root : String
  branch : String
  is_detached : Bool
  commit_hash : String
  staged : Int
  modified : Int
  untracked : Int
  ahead : Int
  behind : Int
}

///|
pub fn GitInfo::new(
  repo_root~ : String,
  branch~ : String,
  is_detached? : Bool = false,
  commit_hash? : String = "",
  staged? : Int = 0,
  modified? : Int = 0,
  untracked? : Int = 0,
  ahead? : Int = 0,
  behind? : Int = 0,
) -> GitInfo {
  {
    repo_root,
    branch,
    is_detached,
    commit_hash,
    staged,
    modified,
    untracked,
    ahead,
    behind,
  }
}

///|
pub fn initialize() -> Bool {
  @libgit2.git_init()
}

///|
pub fn finalize() -> Unit {
  @libgit2.git_shutdown()
}

///|
pub async fn get_info(cwd : String) -> GitInfo? {
  guard @libgit2.is_loaded() else { return None }
  guard @libgit2.Repository::open(cwd) is Some(repo) else { return None }

  let info = build_info(repo, cwd)
  repo.close()
  Some(info)
}

///|
async fn build_info(repo : @libgit2.Repository, cwd : String) -> GitInfo {
  let repo_root = repo_root_from_path(repo.path())

  let (branch, is_detached) = match repo.head_name() {
    Some(name) => (extract_branch_name(name), false)
    None => ("", true)
  }

  let commit_hash = match repo.head_id() {
    Some(id) => if id.length() >= 7 { id[:7].to_string() } else { id }
    None => ""
  }

  let (staged, modified, untracked) = count_status(repo.status_flags())
  let (ahead, behind) = get_ahead_behind(cwd)

  {
    repo_root,
    branch,
    is_detached,
    commit_hash,
    staged,
    modified,
    untracked,
    ahead,
    behind,
  }
}

///|
fn repo_root_from_path(git_path : String) -> String {
  let path = if git_path.has_suffix("/") {
    git_path[:git_path.length() - 1].to_string()
  } else {
    git_path
  }

  if path.has_suffix("/.git") {
    path[:path.length() - 5].to_string()
  } else {
    path
  }
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

///|
async fn get_ahead_behind(cwd : String) -> (Int, Int) {
  let devnull = @process.redirect_to_file("/dev/null")
  let (code, data) = @process.collect_stdout(
    "git",
    ["-C", cwd, "rev-list", "--left-right", "--count", "HEAD...@{u}"][:],
    stderr=devnull,
  ) catch {
    _ => return (0, 0)
  }

  guard code == 0 else { return (0, 0) }

  let output = data.text() catch { _ => return (0, 0) }
  parse_ahead_behind_output(output.trim(chars=" \n\r\t").to_string())
}

///|
fn parse_ahead_behind_output(s : String) -> (Int, Int) {
  match s.split_once("\t") {
    Some((ahead_str, behind_str)) =>
      (
        parse_int_default(ahead_str.to_string()),
        parse_int_default(behind_str.to_string()),
      )
    None => (0, 0)
  }
}

///|
fn parse_int_default(s : String) -> Int {
  @strconv.parse_int(s) catch {
    _ => 0
  }
}
