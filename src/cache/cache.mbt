///|
struct CacheEntry {
  v : Int
  ts : Int64
  status : Int
  prompt : String
} derive(ToJson, FromJson)

///|
let cache_version : Int = 2

///|
pub fn cache_dir() -> String {
  let xdg = @sys.get_env_var("XDG_RUNTIME_DIR").unwrap_or("")

  let base = if not(xdg.is_empty()) {
    "\{xdg}/moonship"
  } else {
    let tmpdir = @sys.get_env_var("TMPDIR").unwrap_or("")
    if not(tmpdir.is_empty()) {
      let trimmed = tmpdir.trim_end(chars="/").to_string()
      "\{trimmed}/moonship"
    } else {
      "/tmp/moonship"
    }
  }

  "\{base}/cache"
}

///|
pub fn read_prompt(cwd : String, status : Int, ttl_ms : Int) -> String? {
  let path = cache_file_path(cache_dir(), cwd)

  let content = @fs.read_file_to_string(path) catch { _ => return None }
  let json : Json = @json.parse(content) catch { _ => return None }
  let entry : CacheEntry = @json.from_json(json) catch { _ => return None }

  guard entry.v == cache_version else { return None }
  guard entry.status == status else { return None }

  let now = @async.now()
  guard now - entry.ts < ttl_ms.to_int64() else { return None }

  Some(entry.prompt)
}

///|
pub fn write_prompt(cwd : String, status : Int, prompt : String) -> Unit {
  let dir = cache_dir()
  ensure_dir(dir)

  let entry : CacheEntry = {
    v: cache_version,
    ts: @async.now(),
    status,
    prompt,
  }
  let path = cache_file_path(dir, cwd)
  @fs.write_string_to_file(path, entry.to_json().stringify()) catch {
    _ => ()
  }
}

///|
pub fn clear_cache() -> Unit {
  let dir = cache_dir()
  let files = @fs.read_dir(dir) catch { _ => return }

  files.each(fn(file) { @fs.remove_file("\{dir}/\{file}") catch { _ => () } })
}

///|
fn cache_file_path(dir : String, cwd : String) -> String {
  "\{dir}/\{hash_path(cwd)}.json"
}

///|
fn hash_path(path : String) -> String {
  path
  .iter()
  .fold(init=5381U, fn(h, ch) { (h << 5) + h + ch.to_uint() })
  .to_string()
}

///|
fn ensure_dir(path : String) -> Unit {
  guard not(@fs.path_exists(path)) else { return }

  path
  .split("/")
  .map(fn(v) { v.to_string() })
  .fold(init="", fn(current, part) {
    let next = if part.is_empty() {
      "/"
    } else if current == "/" {
      "/\{part}"
    } else {
      "\{current}/\{part}"
    }

    if not(@fs.path_exists(next)) {
      @fs.create_dir(next) catch {
        _ => ()
      }
    }

    next
  })
  |> ignore
}
