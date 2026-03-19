///|
struct CacheEntry {
  v : Int
  ts : Int64
  info : @git.GitInfo
} derive(ToJson, FromJson)

///|
let cache_version : Int = 1

///|
pub fn cache_dir() -> String {
  let xdg = @sys.get_env_var("XDG_RUNTIME_DIR").unwrap_or("")

  let base = if not(xdg.is_empty()) {
    xdg + "/moonship"
  } else {
    let tmpdir = @sys.get_env_var("TMPDIR").unwrap_or("")
    if not(tmpdir.is_empty()) {
      tmpdir.trim_end(chars="/").to_string() + "/moonship"
    } else {
      "/tmp/moonship"
    }
  }

  base + "/cache"
}

///|
pub fn read_cache(repo_root : String, ttl_ms : Int) -> @git.GitInfo? {
  let path = cache_file_path(cache_dir(), repo_root)

  let content = @fs.read_file_to_string(path) catch { _ => return None }
  let json : Json = @json.parse(content) catch { _ => return None }
  let entry : CacheEntry = @json.from_json(json) catch { _ => return None }

  guard entry.v == cache_version else { return None }

  let now = @async.now()
  guard now - entry.ts < ttl_ms.to_int64() else { return None }

  Some(entry.info)
}

///|
pub fn write_cache(repo_root : String, info : @git.GitInfo) -> Unit {
  let dir = cache_dir()
  ensure_dir(dir)

  let entry : CacheEntry = { v: cache_version, ts: @async.now(), info }
  let path = cache_file_path(dir, repo_root)
  @fs.write_string_to_file(path, entry.to_json().stringify()) catch { _ => () }
}

///|
pub fn clear_cache() -> Unit {
  let dir = cache_dir()
  let files = @fs.read_dir(dir) catch { _ => return }

  for file in files {
    @fs.remove_file(dir + "/" + file) catch { _ => () }
  }
}

///|
fn cache_file_path(dir : String, repo_root : String) -> String {
  dir + "/" + hash_path(repo_root) + ".json"
}

///|
fn hash_path(path : String) -> String {
  let mut h : UInt = 5381
  for ch in path {
    h = (h << 5) + h + ch.to_uint()
  }
  h.to_string()
}

///|
fn ensure_dir(path : String) -> Unit {
  if @fs.path_exists(path) {
    return
  }

  let parts = path.split("/").map(fn(v) { v.to_string() }).collect()
  let buf = StringBuilder::new()

  for part in parts {
    if part.is_empty() {
      buf.write_char('/')
      continue
    }

    buf.write_string(part)
    let current = buf.to_string()

    if not(@fs.path_exists(current)) {
      @fs.create_dir(current) catch { _ => () }
    }

    buf.write_char('/')
  }
}
