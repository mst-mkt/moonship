///|
pub struct KubernetesModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn KubernetesModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "kubernetes",
  ),
) -> KubernetesModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="☸ "),
  }
}

///|
pub fn KubernetesModule::from_config(
  config : @config.Config,
) -> KubernetesModule {
  KubernetesModule::new(config=config.get_module("kubernetes"))
}

///|
pub impl @ms.PromptModule for KubernetesModule with name(_self) -> String {
  "kubernetes"
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

  let mut current_context = ""
  let mut ns = ""

  for path in kubeconfig_paths {
    let content = @fs.read_file_to_string(path) catch { _ => continue }
    let docs = @yaml.Yaml::load_from_string(content) catch { _ => continue }
    guard docs.length() > 0 else { continue }

    let doc = docs[0]
    let ctx_name = get_yaml_string(doc, "current-context")
    if not(ctx_name.is_empty()) && current_context.is_empty() {
      current_context = ctx_name
      ns = get_context_namespace(doc, ctx_name)
      break
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
  match doc {
    Map(m) =>
      match m.get("contexts") {
        Some(Array(contexts)) => {
          for ctx in contexts {
            match ctx {
              Map(ctx_map) => {
                let name = match ctx_map.get("name") {
                  Some(String(s)) => s
                  _ => ""
                }

                if name == context_name {
                  match ctx_map.get("context") {
                    Some(Map(inner)) =>
                      match inner.get("namespace") {
                        Some(String(ns)) => return ns
                        _ => return ""
                      }
                    _ => return ""
                  }
                }
              }
              _ => ()
            }
          }

          ""
        }
        _ => ""
      }
    _ => ""
  }
}
