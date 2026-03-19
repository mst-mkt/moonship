///|
pub fn wrap_for_shell(shell : String, s : String) -> String {
  if shell == "zsh" {
    wrap_ansi_for_zsh(s)
  } else {
    s
  }
}

///|
pub fn wrap_ansi_for_zsh(s : String) -> String {
  let buf = StringBuilder::new()
  let len = s.length()
  let mut i = 0

  while i < len {
    if i + 1 < len &&
      s[i].unsafe_to_char() == '\u001b' &&
      s[i + 1].unsafe_to_char() == '[' {
      buf.write_string("%{\u001b[")
      i += 2

      while i < len {
        let ch = s[i].unsafe_to_char()
        buf.write_char(ch)
        i += 1
        if ch == 'm' {
          break
        }
      }

      buf.write_string("%}")
    } else {
      buf.write_char(s[i].unsafe_to_char())
      i += 1
    }
  }

  buf.to_string()
}
