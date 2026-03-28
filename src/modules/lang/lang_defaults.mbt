///|
pub fn zig_defaults() -> SimpleLangModule {
  {
    module_name: "zig",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold yellow",
    symbol: "↯ ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".zig"],
    detect_folders: [],
    command: "zig",
    command_args: ["version"],
    detect_label: "Zig",
    version_extract: identity,
  }
}

///|
pub fn buf_defaults() -> SimpleLangModule {
  {
    module_name: "buf",
    disabled: false,
    async_render: false,
    format: "with [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🐃 ",
    version_format: "v${raw}",
    detect_files: ["buf.yaml", "buf.gen.yaml", "buf.work.yaml"],
    detect_extensions: [],
    detect_folders: [],
    command: "buf",
    command_args: ["--version"],
    detect_label: "Buf",
    version_extract: identity,
  }
}

///|
pub fn bun_defaults() -> SimpleLangModule {
  {
    module_name: "bun",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "🥟 ",
    version_format: "v${raw}",
    detect_files: ["bun.lock", "bun.lockb", "bunfig.toml"],
    detect_extensions: [],
    detect_folders: [],
    command: "bun",
    command_args: ["--version"],
    detect_label: "Bun",
    version_extract: identity,
  }
}

///|
pub fn elm_defaults() -> SimpleLangModule {
  {
    module_name: "elm",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    symbol: "🌳 ",
    version_format: "v${raw}",
    detect_files: ["elm.json", "elm-package.json", ".elm-version"],
    detect_extensions: [".elm"],
    detect_folders: ["elm-stuff"],
    command: "elm",
    command_args: ["--version"],
    detect_label: "Elm",
    version_extract: identity,
  }
}

///|
pub fn haskell_defaults() -> SimpleLangModule {
  {
    module_name: "haskell",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold purple",
    symbol: "λ ",
    version_format: "v${raw}",
    detect_files: ["stack.yaml", "cabal.project"],
    detect_extensions: [".hs", ".cabal", ".hs-boot"],
    detect_folders: [],
    command: "ghc",
    command_args: ["--numeric-version"],
    detect_label: "Haskell",
    version_extract: identity,
  }
}

///|
pub fn haxe_defaults() -> SimpleLangModule {
  {
    module_name: "haxe",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold fg:202",
    symbol: "⌘ ",
    version_format: "v${raw}",
    detect_files: ["haxelib.json", "hxformat.json", ".haxerc"],
    detect_extensions: [".hx", ".hxml"],
    detect_folders: [".haxelib", "haxe_libraries"],
    command: "haxe",
    command_args: ["--version"],
    detect_label: "Haxe",
    version_extract: identity,
  }
}

///|
pub fn purescript_defaults() -> SimpleLangModule {
  {
    module_name: "purescript",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    symbol: "<=> ",
    version_format: "v${raw}",
    detect_files: ["spago.dhall", "spago.yaml", "spago.lock"],
    detect_extensions: [".purs"],
    detect_folders: [],
    command: "purs",
    command_args: ["--version"],
    detect_label: "PureScript",
    version_extract: identity,
  }
}

///|
pub fn quarto_defaults() -> SimpleLangModule {
  {
    module_name: "quarto",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #75AADB",
    symbol: "⨁ ",
    version_format: "v${raw}",
    detect_files: ["_quarto.yml"],
    detect_extensions: [".qmd"],
    detect_folders: [],
    command: "quarto",
    command_args: ["--version"],
    detect_label: "Quarto",
    version_extract: identity,
  }
}

///|
pub fn erlang_defaults() -> SimpleLangModule {
  {
    module_name: "erlang",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: " ",
    version_format: "v${raw}",
    detect_files: ["rebar.config", "erlang.mk"],
    detect_extensions: [],
    detect_folders: [],
    command: "erl",
    command_args: [
      "-noshell", "-eval", "Fn=filename:join([code:root_dir(),\"releases\",erlang:system_info(otp_release),\"OTP_VERSION\"]),{ok,Content}=file:read_file(Fn),io:format(\"~s\",[Content]),halt(0).",
    ],
    detect_label: "Erlang",
    version_extract: identity,
  }
}

///|
pub fn php_defaults() -> SimpleLangModule {
  {
    module_name: "php",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "147 bold",
    symbol: "🐘 ",
    version_format: "v${raw}",
    detect_files: ["composer.json", ".php-version"],
    detect_extensions: [".php"],
    detect_folders: [],
    command: "php",
    command_args: [
      "-nr", "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'.'.PHP_RELEASE_VERSION;",
    ],
    detect_label: "PHP",
    version_extract: identity,
  }
}

///|
pub fn perl_defaults() -> SimpleLangModule {
  {
    module_name: "perl",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "149 bold",
    symbol: "🐪 ",
    version_format: "v${raw}",
    detect_files: [
      "Makefile.PL", "Build.PL", "cpanfile", "cpanfile.snapshot", "META.json", "META.yml",
      ".perl-version",
    ],
    detect_extensions: [".pl", ".pm", ".pod"],
    detect_folders: [],
    command: "perl",
    command_args: ["-e", "printf q{%vd},$^V"],
    detect_label: "Perl",
    version_extract: identity,
  }
}

///|
pub fn rust_defaults() -> SimpleLangModule {
  {
    module_name: "rust",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "🦀 ",
    version_format: "v${raw}",
    detect_files: ["Cargo.toml"],
    detect_extensions: [".rs"],
    detect_folders: [],
    command: "rustc",
    command_args: ["--version"],
    detect_label: "Rust",
    version_extract: parse_rustc_version,
  }
}

///|
pub fn dart_defaults() -> SimpleLangModule {
  {
    module_name: "dart",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🎯 ",
    version_format: "v${raw}",
    detect_files: ["pubspec.yaml", "pubspec.yml", "pubspec.lock"],
    detect_extensions: [".dart"],
    detect_folders: [".dart_tool"],
    command: "dart",
    command_args: ["--version"],
    detect_label: "Dart",
    version_extract: parse_dart_version,
  }
}

///|
pub fn crystal_defaults() -> SimpleLangModule {
  {
    module_name: "crystal",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "🔮 ",
    version_format: "v${raw}",
    detect_files: ["shard.yml"],
    detect_extensions: [".cr"],
    detect_folders: [],
    command: "crystal",
    command_args: ["--version"],
    detect_label: "Crystal",
    version_extract: parse_crystal_version,
  }
}

///|
pub fn deno_defaults() -> SimpleLangModule {
  {
    module_name: "deno",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "green bold",
    symbol: "🦕 ",
    version_format: "v${raw}",
    detect_files: [
      "deno.json", "deno.jsonc", "deno.lock", "mod.ts", "deps.ts", "mod.js", "deps.js",
    ],
    detect_extensions: [],
    detect_folders: [],
    command: "deno",
    command_args: ["-V"],
    detect_label: "Deno",
    version_extract: parse_deno_version,
  }
}

///|
pub fn cmake_defaults() -> SimpleLangModule {
  {
    module_name: "cmake",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "△ ",
    version_format: "v${raw}",
    detect_files: ["CMakeLists.txt", "CMakeCache.txt"],
    detect_extensions: [],
    detect_folders: [],
    command: "cmake",
    command_args: ["--version"],
    detect_label: "CMake",
    version_extract: parse_cmake_version,
  }
}

///|
pub fn moonbit_defaults() -> SimpleLangModule {
  {
    module_name: "moonbit",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 125",
    symbol: "🐰 ",
    version_format: "v${raw}",
    detect_files: ["moon.mod.json", "moon.pkg.json"],
    detect_extensions: [".mbt"],
    detect_folders: [],
    command: "moon",
    command_args: ["version"],
    detect_label: "MoonBit",
    version_extract: parse_moon_version,
  }
}

///|
pub fn mojo_defaults() -> SimpleLangModule {
  {
    module_name: "mojo",
    disabled: false,
    async_render: false,
    format: "with [$symbol($version )]($style)",
    style: "bold 208",
    symbol: "🔥 ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".mojo", ".🔥"],
    detect_folders: [],
    command: "mojo",
    command_args: ["--version"],
    detect_label: "Mojo",
    version_extract: parse_mojo_version,
  }
}

///|
pub fn nim_defaults() -> SimpleLangModule {
  {
    module_name: "nim",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "yellow bold",
    symbol: "👑 ",
    version_format: "v${raw}",
    detect_files: ["nim.cfg"],
    detect_extensions: [".nim", ".nims", ".nimble"],
    detect_folders: [],
    command: "nim",
    command_args: ["--version"],
    detect_label: "Nim",
    version_extract: parse_nim_version,
  }
}

///|
pub fn gleam_defaults() -> SimpleLangModule {
  {
    module_name: "gleam",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #FFAFF3",
    symbol: "⭐ ",
    version_format: "v${raw}",
    detect_files: ["gleam.toml"],
    detect_extensions: [".gleam"],
    detect_folders: [],
    command: "gleam",
    command_args: ["--version"],
    detect_label: "Gleam",
    version_extract: parse_gleam_version,
  }
}

///|
pub fn swift_defaults() -> SimpleLangModule {
  {
    module_name: "swift",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 202",
    symbol: "🐦 ",
    version_format: "v${raw}",
    detect_files: ["Package.swift"],
    detect_extensions: [".swift"],
    detect_folders: [],
    command: "swift",
    command_args: ["--version"],
    detect_label: "Swift",
    version_extract: parse_swift_version,
  }
}

///|
pub fn helm_defaults() -> SimpleLangModule {
  {
    module_name: "helm",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    symbol: "⎈ ",
    version_format: "v${raw}",
    detect_files: ["helmfile.yaml", "Chart.yaml"],
    detect_extensions: [],
    detect_folders: [],
    command: "helm",
    command_args: ["version", "--short"],
    detect_label: "Helm",
    version_extract: parse_helm_version,
  }
}

///|
pub fn opa_defaults() -> SimpleLangModule {
  {
    module_name: "opa",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🪖 ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".rego"],
    detect_folders: [],
    command: "opa",
    command_args: ["version"],
    detect_label: "OPA",
    version_extract: parse_opa_version,
  }
}

///|
pub fn typst_defaults() -> SimpleLangModule {
  {
    module_name: "typst",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #0093A7",
    symbol: "t ",
    version_format: "v${raw}",
    detect_files: ["template.typ"],
    detect_extensions: [".typ"],
    detect_folders: [],
    command: "typst",
    command_args: ["--version"],
    detect_label: "Typst",
    version_extract: fn(output) { nth_word(output, 1) },
  }
}

///|
pub fn vlang_defaults() -> SimpleLangModule {
  {
    module_name: "vlang",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    symbol: "V ",
    version_format: "v${raw}",
    detect_files: ["v.mod", "vpkg.json", ".vpkg-lock.json"],
    detect_extensions: [".v"],
    detect_folders: [],
    command: "v",
    command_args: ["version"],
    detect_label: "V",
    version_extract: last_word,
  }
}

///|
pub fn xmake_defaults() -> SimpleLangModule {
  {
    module_name: "xmake",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    symbol: "△ ",
    version_format: "v${raw}",
    detect_files: ["xmake.lua"],
    detect_extensions: [],
    detect_folders: [],
    command: "xmake",
    command_args: ["--version"],
    detect_label: "xmake",
    version_extract: @exec.find_semver,
  }
}

///|
pub fn julia_defaults() -> SimpleLangModule {
  {
    module_name: "julia",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold purple",
    symbol: "ஃ ",
    version_format: "v${raw}",
    detect_files: ["Project.toml", "Manifest.toml"],
    detect_extensions: [".jl"],
    detect_folders: [],
    command: "julia",
    command_args: ["--version"],
    detect_label: "Julia",
    version_extract: parse_julia_version,
  }
}

///|
pub fn rlang_defaults() -> SimpleLangModule {
  {
    module_name: "rlang",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    symbol: "📐 ",
    version_format: "v${raw}",
    detect_files: ["DESCRIPTION"],
    detect_extensions: [".R", ".Rd", ".Rmd", ".Rproj", ".Rsx"],
    detect_folders: [".Rproj.user"],
    command: "R",
    command_args: ["--version"],
    detect_label: "R",
    version_extract: fn(output) { nth_word(output, 2) },
  }
}

///|
pub fn red_defaults() -> SimpleLangModule {
  {
    module_name: "red",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "red bold",
    symbol: "🔺 ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".red", ".reds"],
    detect_folders: [],
    command: "red",
    command_args: ["--version"],
    detect_label: "Red",
    version_extract: parse_red_version,
  }
}

///|
pub fn fennel_defaults() -> SimpleLangModule {
  {
    module_name: "fennel",
    disabled: true,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold green",
    symbol: "🧅 ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".fnl"],
    detect_folders: [],
    command: "fennel",
    command_args: ["--version"],
    detect_label: "Fennel",
    version_extract: parse_fennel_version,
  }
}

///|
pub fn cobol_defaults() -> SimpleLangModule {
  {
    module_name: "cobol",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "⚙️ ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".cbl", ".cob", ".CBL", ".COB"],
    detect_folders: [],
    command: "cobc",
    command_args: ["-version"],
    detect_label: "COBOL",
    version_extract: parse_cobol_version,
  }
}

///|
pub fn vagrant_defaults() -> SimpleLangModule {
  {
    module_name: "vagrant",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    symbol: "⍱ ",
    version_format: "v${raw}",
    detect_files: ["Vagrantfile"],
    detect_extensions: [],
    detect_folders: [],
    command: "vagrant",
    command_args: ["--version"],
    detect_label: "Vagrant",
    version_extract: fn(output) { nth_word(output, 1) },
  }
}

///|
pub fn odin_defaults() -> SimpleLangModule {
  {
    module_name: "odin",
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-blue",
    symbol: "Ø ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".odin"],
    detect_folders: [],
    command: "odin",
    command_args: ["version"],
    detect_label: "Odin",
    version_extract: parse_odin_version,
  }
}
