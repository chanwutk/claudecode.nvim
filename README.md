# codex.nvim

[![Tests](https://github.com/chanwutk/coding-agents.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/chanwutk/coding-agents.nvim/actions/workflows/test.yml)
[![Neovim version](https://img.shields.io/badge/Neovim-0.8%2B-green)](https://neovim.io/)
![Status](https://img.shields.io/badge/Status-beta-blue)

**Neovim integration for the OpenAI Codex CLI** — run Codex in a managed terminal,
send `@path` references and visual selections, and add files from tree explorers.

> **Important**: This **`codex` branch** provides **Codex CLI** support only (managed
> terminal workflow). It does **not** run the WebSocket/MCP server used by Claude Code.
> For Claude Code in Neovim, use [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim).

> **Repository**
> - **Repo**: `chanwutk/coding-agents.nvim`
> - **Branch**: `codex`
> - **Lua module**: `codex` (`require("codex")`)
> - **User commands**: `Codex`, `CodexOpen`, `CodexClose`, `CodexFocus`, `CodexAdd`,
>   `CodexSend`, `CodexTreeAdd`
> - **Default CLI**: `codex` on your `PATH` (override with `terminal_cmd`)

> **Works alongside claudecode.nvim**
> - Different modules (`codex` vs `claudecode`) and different commands (`Codex*` vs
>   `ClaudeCode*`), so both plugins can be installed together if you want both CLIs.

## Quick Start

### Installation with lazy.nvim

Minimal install (defaults: `codex` on `PATH`, terminal provider `auto`):

```lua
{
  "chanwutk/coding-agents.nvim",
  branch = "codex",
  dependencies = { "folke/snacks.nvim" },
}
```

The plugin runs `require("codex").setup(...)` from `plugin/codex.lua` on startup. To pass
options from lazy.nvim, use **`config` and set `vim.g.codex_user_config`** so the same
table is used if setup runs again on `VimEnter`:

```lua
{
  "chanwutk/coding-agents.nvim",
  branch = "codex",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "codex",
    log_level = "info",
    focus_after_send = true,
    track_selection = false,
    terminal = {
      provider = "auto", -- "auto", "snacks", "native", "external", "none", or custom table
      split_side = "right",
      split_width_percentage = 0.30,
    },
  },
  config = function(_, opts)
    vim.g.codex_user_config = opts
    require("codex").setup(opts)
  end,
  keys = {
    { "<leader>a", nil, desc = "AI / Codex" },
    -- Terminal
    { "<leader>ac", "<cmd>Codex<cr>", desc = "Toggle / focus Codex terminal" },
    { "<leader>ao", "<cmd>CodexOpen<cr>", desc = "Open Codex terminal" },
    { "<leader>ax", "<cmd>CodexClose<cr>", desc = "Close Codex terminal" },
    { "<leader>af", "<cmd>CodexFocus<cr>", desc = "Focus / toggle Codex terminal" },
    -- Context (@path and selection)
    { "<leader>ab", "<cmd>CodexAdd %<cr>", desc = "Add current buffer path to Codex" },
    { "<leader>as", "<cmd>CodexSend<cr>", mode = "v", desc = "Send visual selection" },
    {
      "<leader>as",
      "<cmd>CodexTreeAdd<cr>",
      desc = "Add selected path from file tree",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
  },
}
```

**Optional lazy.nvim `name`**: If your URL’s folder name is awkward, you may set
`name = "codex"` for the install path only; `require("codex")` still resolves via
`lua/codex/`.

That's it for defaults — no lock files or MCP server.

## Requirements

- Neovim >= 0.8.0
- [Codex CLI](https://developers.openai.com/codex/cli) installed and available as `codex`
  (or set `terminal_cmd` to the full executable path)
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) recommended — with
  `provider = "auto"`, Snacks is used when available; otherwise Neovim’s native terminal
  is used

## Passing arguments to the Codex CLI

These commands accept trailing arguments (passed through to the spawned Codex process):

- `:Codex …`
- `:CodexOpen …`
- `:CodexFocus …`

Example:

```vim
:Codex --your-cli-flags
```

Exact flags depend on your Codex CLI version; run `codex --help` locally.

## `CodexAdd` — files, directories, and line ranges

```vim
" Current file (from keymap above)
:CodexAdd %

" Explicit path (file or directory)
:CodexAdd path/to/file.lua

" 1-based line range (end optional)
:CodexAdd path/to/file.lua 10 25
```

Line ranges are turned into human-readable “focus on lines …” text plus `@path` style
references sent into the Codex terminal. Directories ignore line numbers.

## `CodexSend` — visual selection

In visual mode, run:

```vim
:'<,'>CodexSend
```

Or use the `v` mode mapping from the lazy snippet. Selection text is sent into the Codex
terminal according to `lua/codex/selection.lua`.

## `CodexTreeAdd` — tree explorers

In a supported tree buffer, add the current node (or nvim-tree marks) to Codex context:

- **NvimTree** (`nvim-tree`)
- **neo-tree**
- **oil.nvim**
- **mini.files**
- **netrw**

Each chosen path is sent as an `@…` reference, same as `CodexAdd`.

## Quick demo

```vim
:CodexOpen
" Type in the Codex TUI as usual.

:'<,'>CodexSend
" Sends the visual selection into the terminal.

:CodexAdd % 42 80
" Adds a line-range hint for the current file.

:CodexClose
```

## Key commands (summary)

| Command | Description |
|--------|----------------|
| `:Codex [args…]` | Toggle / focus Codex terminal; optional CLI args |
| `:CodexOpen [args…]` | Open terminal; optional CLI args |
| `:CodexClose` | Close Codex terminal |
| `:CodexFocus [args…]` | Same toggle/focus behavior as `:Codex` |
| `:CodexAdd {path} [start] [end]` | Send `@path` / line-focus text to Codex |
| `:CodexSend` | Send current visual range to Codex (`:'<,'>CodexSend`) |
| `:CodexTreeAdd` | Add tree selection(s) to Codex |

## Advanced configuration

Top-level options (see `lua/codex/config.lua`):

| Option | Description |
|--------|-------------|
| `terminal_cmd` | Executable or path (default: `"codex"` when unset) |
| `env` | Extra environment variables for the terminal job (`string` → `string`) |
| `log_level` | `"trace"`, `"debug"`, `"info"`, `"warn"`, `"error"` |
| `track_selection` | When `true`, enables selection tracking autocommands |
| `focus_after_send` | After a successful send, focus terminal / insert mode |
| `visual_demotion_delay_ms` | Delay used when demoting visual selection updates |
| `terminal` | Split layout, provider, cwd, external terminal template, etc. |

`terminal` table (defaults in `lua/codex/terminal.lua`):

- `split_side` — `"left"` or `"right"`
- `split_width_percentage` — e.g. `0.30`
- `provider` — `"auto"`, `"snacks"`, `"native"`, `"external"`, `"none"`, or a custom
  provider table
- `auto_close` — close terminal when Neovim exits
- `snacks_win_opts` — forwarded to Snacks when that provider is used
- `cwd` — fixed working directory for the Codex job
- `git_repo_cwd` — use git root derived from current file
- `cwd_provider` — `function(ctx)` returning a directory (`ctx` has `file`, `file_dir`,
  `cwd`)
- `provider_opts.external_terminal_cmd` — must include `%s` for the Codex command (see
  luacheck-validated patterns in `lua/codex/config.lua`)

Top-level aliases forwarded into `terminal` (same as in `codex.setup`):

- `git_repo_cwd`
- `cwd`
- `cwd_provider`

Example — git root as cwd:

```lua
require("codex").setup({
  git_repo_cwd = true,
})
```

Example — custom cwd provider:

```lua
require("codex").setup({
  terminal = {
    cwd_provider = function(ctx)
      local cwd_mod = require("codex.cwd")
      return cwd_mod.git_root(ctx.file_dir or ctx.cwd) or ctx.file_dir or ctx.cwd
    end,
  },
})
```

### External terminal provider

```lua
require("codex").setup({
  terminal = {
    provider = "external",
    provider_opts = {
      external_terminal_cmd = "alacritty -e %s",
    },
  },
})
```

The string **must** contain `%s` for the Codex command (see `lua/codex/config.lua` for
two-placeholder `cwd` + `command` forms).

## Optional: install alongside Claude Code

```lua
return {
  {
    "coder/claudecode.nvim",
    config = true,
  },
  {
    "chanwutk/coding-agents.nvim",
    branch = "codex",
    dependencies = { "folke/snacks.nvim" },
    config = function(_, opts)
      vim.g.codex_user_config = opts
      require("codex").setup(opts)
    end,
  },
}
```

## Troubleshooting

- **`module 'codex' not found`** — Ensure the **`codex` branch** is checked out /
  `branch = "codex"` in lazy, and run `:Lazy install`.
- **Options ignored after startup** — Set `vim.g.codex_user_config` in lazy `config`
  (see above) so `plugin/codex.lua` and `require("codex").setup` stay in sync.
- **Wrong or missing CLI** — Run `which codex` and set `terminal_cmd` to a full path if
  Neovim’s environment differs from your shell.
- **Terminal UI issues** — Try `terminal = { provider = "native" }` if Snacks misbehaves;
  or `provider = "external"` with a valid `external_terminal_cmd`.
- **Debug logs** — `log_level = "debug"` in setup opts.

## Contributing

See [DEVELOPMENT.md](./DEVELOPMENT.md) and [AGENTS.md](./AGENTS.md). Run `make` before
committing.

## License

[MIT](LICENSE)

## Acknowledgements

- [OpenAI Codex CLI](https://developers.openai.com/codex/cli)
- Terminal / explorer patterns aligned with [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)
- Built with assistance from AI
