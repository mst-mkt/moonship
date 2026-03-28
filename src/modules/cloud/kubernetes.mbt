///|
pub struct KubernetesModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  context_aliases : Map[String, String]
  user_aliases : Map[String, String]
  detect_env_vars : Array[String]
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
  contexts : Array[KubernetesContextConfig]
}

///|
pub(all) struct KubernetesContextConfig {
  context_pattern : String
  user_pattern : String
  symbol : String
  style : String
  context_alias : String
  user_alias : String
}

///|
pub fn KubernetesModule::default() -> KubernetesModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$context( \\($namespace\\))]($style) in ",
    style: "cyan bold",
    symbol: "☸ ",
    context_aliases: {},
    user_aliases: {},
    detect_env_vars: [],
    detect_files: [],
    detect_extensions: [],
    detect_folders: [],
    contexts: [],
  }
}

///|
pub fn KubernetesModule::from_table(
  table : @config.ModuleTable,
) -> KubernetesModule {
  let d = KubernetesModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    context_aliases: table.get_string_map("context_aliases"),
    user_aliases: table.get_string_map("user_aliases"),
    detect_env_vars: table
    .get_string_array("detect_env_vars")
    .unwrap_or(d.detect_env_vars),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    contexts: parse_contexts(table),
  }
}

///|
fn parse_contexts(
  table : @config.ModuleTable,
) -> Array[KubernetesContextConfig] {
  match table.0.get("contexts") {
    Some(@config.CArray(arr)) =>
      arr
      .iter()
      .filter_map(fn(item) {
        guard item is @config.CTable(ctx_table) else { return None }

        let get = fn(key : String) -> String {
          match ctx_table.get(key) {
            Some(@config.CString(s)) => s
            _ => ""
          }
        }

        let pattern = get("context_pattern")
        guard not(pattern.is_empty()) else { return None }

        Some({
          context_pattern: pattern,
          user_pattern: get("user_pattern"),
          symbol: get("symbol"),
          style: get("style"),
          context_alias: get("context_alias"),
          user_alias: get("user_alias"),
        })
      })
      .collect()
    _ => []
  }
}

///|
pub fn KubernetesModule::from_config(
  config : @config.Config,
) -> KubernetesModule {
  match config.get_raw_module("kubernetes") {
    Some(table) => KubernetesModule::from_table(table)
    None => KubernetesModule::default()
  }
}

///|
pub impl @ms.PromptModule for KubernetesModule with name(_self) -> String {
  "kubernetes"
}

///|
pub impl @ms.PromptModule for KubernetesModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for KubernetesModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  // Check detect conditions if any are configured
  let has_detect = not(self.detect_files.is_empty()) ||
    not(self.detect_extensions.is_empty()) ||
    not(self.detect_folders.is_empty()) ||
    not(self.detect_env_vars.is_empty())

  if has_detect {
    let file_match = @exec.detect_project(
      ctx.cwd,
      self.detect_files,
      self.detect_extensions,
      folders=self.detect_folders,
    )
    let env_match = self.detect_env_vars
      .iter()
      .any(fn(name) { not(@sys.get_env_var(name).unwrap_or("").is_empty()) })

    guard file_match || env_match else {
      return Skipped("detection conditions not met")
    }
  }

  let kubeconfig_paths = get_kubeconfig_paths(ctx.home_dir)
  guard not(kubeconfig_paths.is_empty()) else {
    return Skipped("no kubeconfig path")
  }

  let (current_context, ns) = loop 0 {
    i if i >= kubeconfig_paths.length() => break ("", "")
    i => {
      let path = kubeconfig_paths[i]
      let content = @fs.read_file_to_string(path) catch { _ => continue i + 1 }
      let docs = @yaml.Yaml::load_from_string(content) catch {
        _ => continue i + 1
      }
      guard docs.length() > 0 else { continue i + 1 }

      let doc = docs[0]
      let ctx_name = get_yaml_string(doc, "current-context")
      if not(ctx_name.is_empty()) {
        break (ctx_name, get_context_namespace(doc, ctx_name))
      }
      continue i + 1
    }
  }

  guard not(current_context.is_empty()) else {
    return Skipped("no current context")
  }

  let user = get_context_user(kubeconfig_paths, current_context)

  // Find matching per-context config (exact match on context_pattern)
  let ctx_config = self.contexts
    .iter()
    .find_first(fn(c) {
      c.context_pattern == current_context &&
      (c.user_pattern.is_empty() || c.user_pattern == user)
    })

  let display_context = match ctx_config {
    Some(c) if not(c.context_alias.is_empty()) => c.context_alias
    _ => self.context_aliases.get(current_context).unwrap_or(current_context)
  }

  let display_user = if user.is_empty() {
    ""
  } else {
    match ctx_config {
      Some(c) if not(c.user_alias.is_empty()) => c.user_alias
      _ => self.user_aliases.get(user).unwrap_or(user)
    }
  }

  let symbol = match ctx_config {
    Some(c) if not(c.symbol.is_empty()) => c.symbol
    _ => self.symbol
  }

  let style = match ctx_config {
    Some(c) if not(c.style.is_empty()) => c.style
    _ => self.style
  }

  let vars : Map[String, String] = {
    "context": display_context,
    "symbol": symbol,
    "style": style,
  }

  if not(ns.is_empty()) {
    vars["namespace"] = ns
  }

  if not(display_user.is_empty()) {
    vars["user"] = display_user
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn get_kubeconfig_paths(home_dir : String) -> Array[String] {
  let env = @sys.get_env_var("KUBECONFIG").unwrap_or("")
  if not(env.is_empty()) {
    return @exec.split_to_strings(env, ":")
  }

  if not(home_dir.is_empty()) {
    [home_dir + "/.kube/config"]
  } else {
    []
  }
}

///|
fn get_yaml_string(doc : @yaml.Yaml, key : String) -> String {
  match doc {
    Map(m) =>
      match m.get(key) {
        Some(String(s)) => s
        _ => ""
      }
    _ => ""
  }
}

///|
fn get_context_namespace(doc : @yaml.Yaml, context_name : String) -> String {
  guard doc is Map(m) else { return "" }
  guard m.get("contexts") is Some(Array(contexts)) else { return "" }

  contexts
  .iter()
  .find_first(fn(ctx) {
    guard ctx is Map(ctx_map) else { return false }
    match ctx_map.get("name") {
      Some(String(s)) => s == context_name
      _ => false
    }
  })
  .map(fn(ctx) {
    guard ctx is Map(ctx_map) else { return "" }
    guard ctx_map.get("context") is Some(Map(inner)) else { return "" }
    match inner.get("namespace") {
      Some(String(ns)) => ns
      _ => ""
    }
  })
  .unwrap_or("")
}

///|
fn get_context_user(
  kubeconfig_paths : Array[String],
  context_name : String,
) -> String {
  for path in kubeconfig_paths {
    let content = @fs.read_file_to_string(path) catch { _ => continue }
    let docs = @yaml.Yaml::load_from_string(content) catch { _ => continue }
    guard docs.length() > 0 else { continue }

    let doc = docs[0]
    guard doc is Map(m) else { continue }
    guard m.get("contexts") is Some(Array(contexts)) else { continue }

    for ctx in contexts {
      guard ctx is Map(ctx_map) else { continue }
      guard ctx_map.get("name") is Some(String(name)) else { continue }
      guard name == context_name else { continue }
      guard ctx_map.get("context") is Some(Map(inner)) else { continue }

      match inner.get("user") {
        Some(String(u)) => return u
        _ => ()
      }
    }
  }

  ""
}

///|
pub fn KubernetesModule::schema() -> @config.ModuleSchema {
  let d = KubernetesModule::default()
  {
    name: "kubernetes",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_env_vars",
        field_type: @config.FStringArray,
        default_value: d.detect_env_vars.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
    ],
  }
}
