-- Installs, and waits for, what the config otherwise fetches in the background
-- the first time nvim starts with a window: the language servers of mason and
-- the treesitter parsers. Run by `dot nvim-setup`, so that a new machine is
-- ready before nvim is first opened:
--
--   nvim --headless -c "lua dofile('<this file>').run()"
--
-- mason-lspconfig installs nothing at all in a headless nvim, which is the only
-- kind a bootstrap script can start. Both lists are read from the config
-- (opts.servers of nvim-lspconfig, vim.g.treesitter_parsers), not repeated here.

local M = {}

local function say(text)
    io.stdout:write(text .. "\n")
end

---The mason packages of the configured servers that are not installed yet.
local function missing_servers()
    local registry = require('mason-registry')
    local to_package = require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package
    local missing = {}
    for _, server in ipairs(require('mason-lspconfig.settings').current.ensure_installed) do
        local name = to_package[server]
        if not name then
            say("  ! " .. server .. ": no mason package under that name")
        elseif not registry.is_installed(name) then
            missing[#missing + 1] = name
        end
    end
    return missing
end

---The parsers of the config that are not installed yet.
local function missing_parsers()
    local installed = {}
    for _, lang in ipairs(require('nvim-treesitter').get_installed()) do installed[lang] = true end
    local missing = {}
    for _, lang in ipairs(vim.g.treesitter_parsers or {}) do
        if not installed[lang] then missing[#missing + 1] = lang end
    end
    return missing
end

---Installs what is missing and exits: 0 when everything is there, 1 otherwise.
function M.run()
    local ok, err = pcall(function()
        require('mason-registry').refresh() -- without a callback this waits

        -- Through mason's API rather than :MasonInstall, which turns whatever an
        -- installer prints on stderr (go: downloading ...) into a Vim error.
        local servers = missing_servers()
        if #servers > 0 then
            say("  language servers to install: " .. table.concat(servers, " "))
            local pending = #servers
            for _, name in ipairs(servers) do
                require('mason-registry').get_package(name):install({}, function(success, result)
                    say(("  %s %s%s"):format(success and "+" or "!", name, success and "" or (": " .. tostring(result))))
                    pending = pending - 1
                end)
            end
            vim.wait(30 * 60 * 1000, function() return pending == 0 end, 200)
        end

        local parsers = missing_parsers()
        if #parsers > 0 then
            say("  treesitter parsers to build: " .. table.concat(parsers, " "))
            require('nvim-treesitter').install(parsers):wait(15 * 60 * 1000)
        end

        servers, parsers = missing_servers(), missing_parsers()
        if #servers + #parsers > 0 then
            error("still missing: " .. table.concat(vim.list_extend(servers, parsers), " "), 0)
        end
        say(("  language servers: %d, treesitter parsers: %d, all installed"):format(
            #require('mason-lspconfig.settings').current.ensure_installed, #(vim.g.treesitter_parsers or {})))
    end)
    if not ok then
        say("  nvim_setup: " .. tostring(err))
        vim.cmd("cquit 1")
    end
    vim.cmd("qall!")
end

return M
