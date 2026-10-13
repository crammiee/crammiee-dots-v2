-- Point pyright at the project's uv-managed .venv, so no repo needs venvPath/venv in pyproject.toml.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        on_init = function(client)
          local python = (client.root_dir or vim.fn.getcwd()) .. "/.venv/bin/python"
          if vim.uv.fs_stat(python) then
            client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
              python = { pythonPath = python },
            })
            client:notify("workspace/didChangeConfiguration", { settings = client.settings })
          end
        end,
      },
    },
  },
}
