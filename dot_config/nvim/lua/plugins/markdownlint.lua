-- Point markdownlint-cli2 at a global config so line-length (MD013) etc. stay off in every repo.
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint-cli2.yaml", "--" },
      },
    },
  },
}
