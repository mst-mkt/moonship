///|
pub(all) enum Shell {
  Zsh
  Bash
  Fish
}

///|
pub fn Shell::from_string(name : String) -> Shell? {
  match name {
    "zsh" => Some(Zsh)
    "bash" => Some(Bash)
    "fish" => Some(Fish)
    _ => None
  }
}

///|
pub fn Shell::to_string(self : Shell) -> String {
  match self {
    Zsh => "zsh"
    Bash => "bash"
    Fish => "fish"
  }
}

///|
fn escape_shell_single_quote(s : String) -> String {
  let buf = StringBuilder::new()

  for ch in s {
    match ch {
      '\'' => buf.write_string("'\\''")
      _ => buf.write_char(ch)
    }
  }

  buf.to_string()
}

///|
fn escape_fish_single_quote(s : String) -> String {
  let buf = StringBuilder::new()

  for ch in s {
    match ch {
      '\\' => buf.write_string("\\\\")
      '\'' => buf.write_string("\\'")
      _ => buf.write_char(ch)
    }
  }

  buf.to_string()
}

///|
pub fn generate_init(shell : Shell, binary_path : String) -> String {
  let template = match shell {
    Zsh => init_zsh_script
    Bash => init_bash_script
    Fish => init_fish_script
  }

  let escaped = match shell {
    Zsh | Bash => escape_shell_single_quote(binary_path)
    Fish => escape_fish_single_quote(binary_path)
  }

  template.replace(old="::BIN::", new=escaped)
}

///|
pub fn generate_init_stub(shell : Shell, binary_path : String) -> String {
  let escaped = match shell {
    Zsh | Bash => escape_shell_single_quote(binary_path)
    Fish => escape_fish_single_quote(binary_path)
  }

  match shell {
    Zsh => "eval \"$('\{escaped}' init zsh --print-full-init)\""
    Bash => "eval \"$('\{escaped}' init bash --print-full-init)\""
    Fish => "source ('\{escaped}' init fish --print-full-init | psub)"
  }
}
