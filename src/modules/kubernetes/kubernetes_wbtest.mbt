///|
async test "name" {
  let m : &@ms.PromptModule = KubernetesModule::default()
  assert_eq(m.name(), "kubernetes")
}

///|
async test "execute: disabled by default" {
  let m = KubernetesModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

// --- context_aliases ---

///|
test "from_table: context_aliases parsed from config" {
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|
      #|[kubernetes.context_aliases]
      #|"arn:aws:eks:us-east-1:123456789:cluster/prod" = "prod"
    ),
  )
  let m = KubernetesModule::from_config(config)
  assert_eq(
    m.context_aliases.get("arn:aws:eks:us-east-1:123456789:cluster/prod"),
    Some("prod"),
  )
}

///|
test "from_table: user_aliases parsed from config" {
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|
      #|[kubernetes.user_aliases]
      #|"admin@prod" = "admin"
    ),
  )
  let m = KubernetesModule::from_config(config)
  assert_eq(m.user_aliases.get("admin@prod"), Some("admin"))
}

///|
test "from_table: detect_env_vars parsed" {
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|detect_env_vars = ["KUBECONFIG"]
    ),
  )
  let m = KubernetesModule::from_config(config)
  assert_eq(m.detect_env_vars, ["KUBECONFIG"])
}

///|
test "from_table: detect_files parsed" {
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|detect_files = ["k8s.yaml"]
    ),
  )
  let m = KubernetesModule::from_config(config)
  assert_eq(m.detect_files, ["k8s.yaml"])
}

// --- get_yaml_string ---

///|
test "get_yaml_string: extracts string value" {
  let docs = @yaml.Yaml::load_from_string(
    (
      #|current-context: my-context
    ),
  )
  assert_eq(get_yaml_string(docs[0], "current-context"), "my-context")
}

///|
test "get_yaml_string: missing key returns empty" {
  let docs = @yaml.Yaml::load_from_string(
    (
      #|foo: bar
    ),
  )
  assert_eq(get_yaml_string(docs[0], "missing"), "")
}

// --- get_context_namespace ---

///|
test "get_context_namespace: extracts namespace" {
  let docs = @yaml.Yaml::load_from_string(
    (
      #|current-context: prod
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      namespace: production
      #|      cluster: prod-cluster
    ),
  )
  assert_eq(get_context_namespace(docs[0], "prod"), "production")
}

///|
test "get_context_namespace: no matching context" {
  let docs = @yaml.Yaml::load_from_string(
    (
      #|current-context: staging
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      namespace: production
    ),
  )
  assert_eq(get_context_namespace(docs[0], "staging"), "")
}

///|
test "get_context_namespace: no namespace field" {
  let docs = @yaml.Yaml::load_from_string(
    (
      #|current-context: prod
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      cluster: prod-cluster
    ),
  )
  assert_eq(get_context_namespace(docs[0], "prod"), "")
}

// --- get_context_user ---

///|
test "get_context_user: extracts user" {
  let path = "/tmp/moonship-test-k8s-user"
  @fs.write_string_to_file(
    path,
    (
      #|current-context: prod
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      user: admin@prod
    ),
  )

  assert_eq(get_context_user([path], "prod"), "admin@prod")
  @fs.remove_file(path) catch { _ => () }
}

///|
test "get_context_user: no user field" {
  let path = "/tmp/moonship-test-k8s-nouser"
  @fs.write_string_to_file(
    path,
    (
      #|current-context: prod
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      cluster: prod-cluster
    ),
  )

  assert_eq(get_context_user([path], "prod"), "")
  @fs.remove_file(path) catch { _ => () }
}

// --- execute integration tests ---

///|
async test "execute: renders context from kubeconfig" {
  let kubeconfig = "/tmp/moonship-test-k8s-exec"
  @fs.write_string_to_file(
    kubeconfig,
    (
      #|current-context: my-prod
      #|contexts:
      #|  - name: my-prod
      #|    context:
      #|      namespace: default
      #|      cluster: prod-cluster
    ),
  )

  @sys.set_env_var("KUBECONFIG", kubeconfig)
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
    ),
  )
  let m = KubernetesModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    @sys.unset_env_var("KUBECONFIG")
    @fs.remove_file(kubeconfig) catch { _ => () }
    fail("expected Output")
    return
  }

  let rendered = out.render()
  assert_true(rendered.contains("my-prod"))
  assert_true(rendered.contains("default"))

  @sys.unset_env_var("KUBECONFIG")
  @fs.remove_file(kubeconfig) catch { _ => () }
}

///|
async test "execute: context_aliases replaces context in output" {
  let kubeconfig = "/tmp/moonship-test-k8s-alias"
  @fs.write_string_to_file(
    kubeconfig,
    (
      #|current-context: arn:aws:eks:us-east-1:123:cluster/prod
      #|contexts:
      #|  - name: "arn:aws:eks:us-east-1:123:cluster/prod"
      #|    context:
      #|      cluster: prod
    ),
  )

  @sys.set_env_var("KUBECONFIG", kubeconfig)
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|
      #|[kubernetes.context_aliases]
      #|"arn:aws:eks:us-east-1:123:cluster/prod" = "prod"
    ),
  )
  let m = KubernetesModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  guard m.execute(ctx) is Output(out) else {
    @sys.unset_env_var("KUBECONFIG")
    @fs.remove_file(kubeconfig) catch { _ => () }
    fail("expected Output")
    return
  }

  let rendered = out.render()
  // The alias "prod" should appear, not the full ARN
  assert_true(rendered.contains("prod"))
  assert_false(rendered.contains("arn:aws"))

  @sys.unset_env_var("KUBECONFIG")
  @fs.remove_file(kubeconfig) catch { _ => () }
}

///|
async test "execute: detect_files skips when no matching file" {
  let kubeconfig = "/tmp/moonship-test-k8s-detect"
  @fs.write_string_to_file(
    kubeconfig,
    (
      #|current-context: test
      #|contexts:
      #|  - name: test
      #|    context:
      #|      cluster: test
    ),
  )

  @sys.set_env_var("KUBECONFIG", kubeconfig)
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
      #|detect_files = ["nonexistent-k8s-file.yaml"]
    ),
  )
  let m = KubernetesModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  assert_true(m.execute(ctx) is Skipped(_))

  @sys.unset_env_var("KUBECONFIG")
  @fs.remove_file(kubeconfig) catch { _ => () }
}

///|
async test "execute: no detect conditions shows unconditionally" {
  let kubeconfig = "/tmp/moonship-test-k8s-nodetect"
  @fs.write_string_to_file(
    kubeconfig,
    (
      #|current-context: test
      #|contexts:
      #|  - name: test
      #|    context:
      #|      cluster: test
    ),
  )

  @sys.set_env_var("KUBECONFIG", kubeconfig)
  let config = @config.Config::from_toml(
    (
      #|[kubernetes]
      #|disabled = false
    ),
  )
  let m = KubernetesModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)

  // No detect_files/detect_env_vars/detect_extensions/detect_folders configured
  // Module should show unconditionally
  assert_true(m.execute(ctx) is Output(_))

  @sys.unset_env_var("KUBECONFIG")
  @fs.remove_file(kubeconfig) catch { _ => () }
}

///|
test "get_context_user: no matching context" {
  let path = "/tmp/moonship-test-k8s-nomatch"
  @fs.write_string_to_file(
    path,
    (
      #|current-context: staging
      #|contexts:
      #|  - name: prod
      #|    context:
      #|      user: admin
    ),
  )

  assert_eq(get_context_user([path], "staging"), "")
  @fs.remove_file(path) catch { _ => () }
}
