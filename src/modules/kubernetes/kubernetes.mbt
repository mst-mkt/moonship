///|
pub struct KubernetesModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn KubernetesModule::default() -> KubernetesModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$context( \\($namespace\\))]($style) in ",
    style: "cyan bold",
    symbol: "☸ ",
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

  let vars : Map[String, String] = {
    "context": current_context,
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(ns.is_empty()) {
    vars["namespace"] = ns
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
    return env.split(":").map(fn(p) { p.to_string() }).collect()
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
    ],
  }
}
