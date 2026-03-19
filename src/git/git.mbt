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
} derive(Show, Eq, ToJson, FromJson)

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

  let repo_root = git_toplevel(cwd)
  guard @libgit2.Repository::open(repo_root) is Some(repo) else { return None }

  let info = build_info(repo, repo_root, cwd)
  repo.close()
  Some(info)
}

///|
async fn git_toplevel(cwd : String) -> String {
  git_cmd_output(cwd, ["rev-parse", "--show-toplevel"]).unwrap_or(cwd)
}

///|
async fn build_info(
  repo : @libgit2.Repository,
  repo_root : String,
  cwd : String,
) -> GitInfo {
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
async fn git_cmd_output(cwd : String, args : Array[String]) -> String? {
  let full_args = ["-C", cwd] + args
  let devnull = @process.redirect_to_file("/dev/null")
  let (code, data) = @process.collect_stdout(
    "git",
    full_args[:],
    stderr=devnull,
  ) catch {
    _ => return None
  }

  guard code == 0 else { return None }

  let output = data.text() catch { _ => return None }
  let trimmed = output.trim(chars=" \n\r\t").to_string()

  guard not(trimmed.is_empty()) else { return None }
  Some(trimmed)
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
  match
    git_cmd_output(cwd, ["rev-list", "--left-right", "--count", "HEAD...@{u}"]) {
    Some(output) => parse_ahead_behind_output(output)
    None => (0, 0)
  }
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
