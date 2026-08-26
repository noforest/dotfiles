-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

local function should_show_image()
    local ui = vim.api.nvim_list_uis()[1]          -- Récupère les dimensions du terminal
    return ui and ui.width > 50 and ui.height > 40 -- Ajuste ces valeurs selon tes besoins
end


local picker_state = {
    history = {},
}

local function navigate_to_parent_smooth(picker)
    local current_cwd = picker.opts.cwd or vim.loop.cwd()
    local parent_dir = vim.fs.dirname(current_cwd)

    if parent_dir and parent_dir ~= current_cwd then
        -- Enregistre le répertoire actuel dans l’historique
        table.insert(picker_state.history, current_cwd)

        -- Mise à jour du répertoire
        vim.cmd("cd " .. vim.fn.fnameescape(parent_dir))
        picker:close()

        vim.defer_fn(function()
            require("snacks").picker.files({
                cwd = parent_dir,
                prompt_title = vim.fs.basename(parent_dir),
            })
        end, 50)
    end
end

local function navigate_back_smooth(picker)
    local previous = table.remove(picker_state.history)
    if previous and vim.fn.isdirectory(previous) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(previous))
        picker:close()

        vim.defer_fn(function()
            require("snacks").picker.files({
                cwd = previous,
                prompt_title = vim.fs.basename(previous),
            })
        end, 50)
    else
        vim.notify("📁 No previous directory in history", vim.log.levels.INFO)
    end
end


require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    -- { "rafi/awesome-vim-colorschemes", priority = 1000 },
    {"Sly-Harvey/radium.nvim", priority = 1000},
    {"projekt0n/github-nvim-theme", priority = 1000},
    {"sainnhe/gruvbox-material", priority = 1000},
    { "ellisonleao/gruvbox.nvim", priority = 1000 , config = true, opts = ...},
    {"Mofiqul/vscode.nvim", priority = 1000},
    { 'Everblush/nvim', name = 'everblush' },
    {"https://github.com/thiagopnts/jellybeans", dependencies = {"rktjmp/lush.nvim"}},
    {
        "HoNamDuong/hybrid.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    {
        "navarasu/onedark.nvim",
        config = function()
            require("onedark").setup({
                style = "dark",
            })
            require("onedark").load()
        end
    },

    -- {
    --   'nvim-telescope/telescope.nvim',
    --   -- tag = '0.1.8',
    --   dependencies = { 'nvim-lua/plenary.nvim' },
    --   config = function()
    --     local telescope = require("telescope")
    --     local actions = require("telescope.actions")
    --     local action_state = require('telescope.actions.state')
    --     local bufferline = require('bufferline')
    --     local sorters = require('telescope.sorters')
    --     local devicons = require("nvim-web-devicons")
    --     local entry_display = require("telescope.pickers.entry_display")
    --
    --
    --     telescope.setup({
    --       file_ignore_patterns = { "%.git/." },
    --       defaults = {
    --         mappings = {
    --           -- i = {
    --           --   ["<Tab>"] = actions.select_default,
    --           -- },
    --           -- n = {
    --           --   ["<Tab>"] = actions.select_default,
    --           -- }
    --         },
    --         path_display = {
    --           "filename_first",
    --
    --         },
    --         -- previewer = true,
    --         file_ignore_patterns = { "node_modules", "package-lock.json" },
    --         initial_mode = "insert",
    --         select_strategy = "reset",
    --         sorting_strategy = "ascending",
    --         color_devicons = true,
    --         set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
    --         layout_config = {
    --           prompt_position = "top",
    --           preview_cutoff = 120,
    --         },
    --         vimgrep_arguments = {
    --           "rg",
    --           "--color=never",
    --           "--no-heading",
    --           "--with-filename",
    --           "--line-number",
    --           "--column",
    --           "--smart-case",
    --           "--hidden",
    --           "--glob=!.git/",
    --         },
    --
    --       },
    --       pickers = {
    --         find_files = {
    --           -- previewer = false,
    --           -- path_display = formattedName,
    --           sort_mru = true,
    --           layout_config = {
    --             -- height = 0.4,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --
    --           },
    --
    --           -- mappings = {
    --           --     i = {
    --           --         ["<C-up>"] = function(prompt_bufnr)
    --           --             local current_picker =
    --           --             require("telescope.actions.state").get_current_picker(prompt_bufnr)
    --           --             -- cwd is only set if passed as telescope option
    --           --             local cwd = current_picker.cwd and tostring(current_picker.cwd)
    --           --             or vim.loop.cwd()
    --           --             local parent_dir = vim.fs.dirname(cwd)
    --           --
    --           --             require("telescope.actions").close(prompt_bufnr)
    --           --             require("telescope.builtin").find_files {
    --           --                 prompt_title = vim.fs.basename(parent_dir),
    --           --                 cwd = parent_dir,
    --           --             }
    --           --         end,
    --           --     },
    --           -- },
    --         },
    --         git_files = {
    --           -- previewer = false,
    --           -- path_display = formattedName,
    --           layout_config = {
    --             -- height = 0.4,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --         },
    --
    --         buffers = {
    --           mappings = {
    --             n = {
    --               ["<Del>"] = actions.delete_buffer,
    --               ["<BS>"] = actions.delete_buffer,
    --             },
    --           },
    --           previewer = false,
    --           initial_mode = "normal",
    --           -- theme = "dropdown",
    --           layout_config = {
    --             height = 0.4,
    --             width = 0.6,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --           sort_mru = true;
    --           ignore_current_buffer = true, -- Ignorer le buffer actif
    --         },
    --         current_buffer_fuzzy_find = {
    --           previewer = true,
    --           layout_config = {
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --         },
    --
    --         -- *************** VERSION AVC CHEMIN MAIS quand meme fichiers ************************
    --         live_grep = (function()
    --             local filename_registry = {}
    --
    --             return {
    --                 attach_mappings = function(_, map)
    --                     filename_registry = {}
    --                     vim.schedule(function()
    --                         -- Création des highlights si non existants
    --                         vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --                         vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --                     end)
    --                     return true
    --                 end,
    --
    --                 entry_maker = function(line)
    --                     local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    --                     if not filename then return end
    --
    --                     local full_path = vim.fn.fnamemodify(filename, ":p")
    --                     local basename = vim.fn.fnamemodify(full_path, ":t")
    --                     local dir_path = vim.fn.fnamemodify(full_path, ":h")
    --                     local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"
    --
    --                     -- Gestion des doublons
    --                     if not filename_registry[basename] then
    --                         filename_registry[basename] = {
    --                             dirs = { [dir_path] = true },
    --                             count = 1
    --                         }
    --                     else
    --                         if not filename_registry[basename].dirs[dir_path] then
    --                             filename_registry[basename].count = filename_registry[basename].count + 1
    --                             filename_registry[basename].dirs[dir_path] = true
    --                         end
    --                     end
    --
    --                     local show_path = filename_registry[basename].count > 1
    --                     local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
    --                     icon = icon or ""
    --                     icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil
    --
    --                     local icon_width = vim.fn.strwidth(icon)
    --                     local dir_width = vim.fn.strwidth(relative_dir)
    --
    --                     return {
    --                         value = line,
    --                         ordinal = basename .. " " .. text,
    --                         display = function()
    --                             local display_text = icon .. " "
    --                             local highlights = {}
    --
    --                             -- Highlight pour l'icône
    --                             table.insert(highlights, {
    --                                 { 0, icon_width + 1 },
    --                                 icon_hl
    --                             })
    --
    --                             if show_path then
    --                                 display_text = display_text .. relative_dir
    --                                 -- Highlight pour le chemin
    --                                 table.insert(highlights, {
    --                                     { icon_width + 2, icon_width + 2 + dir_width },
    --                                     "TelescopePathSeparator"
    --                                 })
    --                             end
    --
    --                             display_text = display_text .. basename
    --
    --                             return display_text, highlights
    --                         end,
    --                         filename = filename,
    --                         lnum = tonumber(lnum),
    --                         col = tonumber(col)
    --                     }
    --                 end
    --             }
    --         end)(),
    --
    --
    --         grep_string = (function()
    --             local filename_registry = {}
    --
    --             return {
    --                 attach_mappings = function(_, map)
    --                     filename_registry = {}
    --                     vim.schedule(function()
    --                         -- Création des highlights si non existants
    --                         vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --                         -- vim.api.nvim_set_hl(0, "DevIconDefault", { fg = "#FFFFFF" })
    --                         vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --                     end)
    --                     return true
    --                 end,
    --
    --                 entry_maker = function(line)
    --                     local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    --                     if not filename then return end
    --
    --                     local full_path = vim.fn.fnamemodify(filename, ":p")
    --                     local basename = vim.fn.fnamemodify(full_path, ":t")
    --                     local dir_path = vim.fn.fnamemodify(full_path, ":h")
    --                     local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"
    --
    --                     -- Gestion des doublons
    --                     if not filename_registry[basename] then
    --                         filename_registry[basename] = {
    --                             dirs = { [dir_path] = true },
    --                             count = 1
    --                         }
    --                     else
    --                         if not filename_registry[basename].dirs[dir_path] then
    --                             filename_registry[basename].count = filename_registry[basename].count + 1
    --                             filename_registry[basename].dirs[dir_path] = true
    --                         end
    --                     end
    --
    --                     local show_path = filename_registry[basename].count > 1
    --                     local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
    --                     icon = icon or ""
    --                     icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil
    --
    --                     local icon_width = vim.fn.strwidth(icon)
    --                     local dir_width = vim.fn.strwidth(relative_dir)
    --
    --                     return {
    --                         value = line,
    --                         ordinal = basename .. " " .. text,
    --                         display = function()
    --                             local display_text = icon .. " "
    --                             local highlights = {}
    --
    --                             -- Highlight pour l'icône
    --                             table.insert(highlights, {
    --                                 { 0, icon_width + 1 },
    --                                 icon_hl
    --                             })
    --
    --                             if show_path then
    --                                 display_text = display_text .. relative_dir
    --                                 -- Highlight pour le chemin
    --                                 table.insert(highlights, {
    --                                     { icon_width + 2, icon_width + 2 + dir_width },
    --                                     "TelescopePathSeparator"
    --                                 })
    --                             end
    --
    --                             display_text = display_text .. basename
    --
    --                             return display_text, highlights
    --                         end,
    --                         filename = filename,
    --                         lnum = tonumber(lnum),
    --                         col = tonumber(col)
    --                     }
    --                 end
    --             }
    --         end)(),
    --
    --
    --         -- *********** SANS CHEMIN GRIS *********************
    --         -- grep_string = {
    --         --     -- Désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         -- line au format : "filepath:line:col:text"
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local basename = filename and vim.fn.fnamemodify(filename, ":t") or line
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(basename, nil, { default = true })
    --         --
    --         --         local displayer = entry_display.create({
    --         --             separator = " ",
    --         --             items = {
    --         --                 { width = 2 }, -- icône
    --         --                 { remaining = true }, -- filename
    --         --             },
    --         --         })
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = basename,
    --         --             display = function(entry)
    --         --                 return displayer({
    --         --                     { icon, icon_hl },
    --         --                     basename,
    --         --                 })
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         --
    --         -- },
    --
    --         -- **************** VERSION AVEC CHEMIN RELATIF EN GRIS ********************
    --         -- live_grep = {
    --         --     -- désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --             -- Définit la couleur grise pour le chemin
    --         --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local directory, filename_part = "", line
    --         --
    --         --         if filename then
    --         --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
    --         --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
    --         --             if not directory then
    --         --                 directory = ""
    --         --                 filename_part = relative_path
    --         --             end
    --         --         end
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
    --         --         icon = icon or ""
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = filename_part,
    --         --             display = function(entry)
    --         --                 local icon_padding = icon .. " "
    --         --                 local display_line = icon_padding .. directory .. filename_part
    --         --
    --         --                 local highlights = {
    --         --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
    --         --                 }
    --         --
    --         --                 if #directory > 0 then
    --         --                     table.insert(highlights, {
    --         --                         { #icon_padding, #icon_padding + #directory },
    --         --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
    --         --                     })
    --         --                 end
    --         --
    --         --                 return display_line, highlights
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         -- },
    --         --
    --         -- grep_string = {
    --         --
    --         --     -- désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --             -- Définit la couleur grise pour le chemin
    --         --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local directory, filename_part = "", line
    --         --
    --         --         if filename then
    --         --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
    --         --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
    --         --             if not directory then
    --         --                 directory = ""
    --         --                 filename_part = relative_path
    --         --             end
    --         --         end
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
    --         --         icon = icon or ""
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = filename_part,
    --         --             display = function(entry)
    --         --                 local icon_padding = icon .. " "
    --         --                 local display_line = icon_padding .. directory .. filename_part
    --         --
    --         --                 local highlights = {
    --         --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
    --         --                 }
    --         --
    --         --                 if #directory > 0 then
    --         --                     table.insert(highlights, {
    --         --                         { #icon_padding, #icon_padding + #directory },
    --         --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
    --         --                     })
    --         --                 end
    --         --
    --         --                 return display_line, highlights
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         --
    --         -- },
    --         lsp_references = {
    --           show_line = false,
    --           previewer = true,
    --         },
    --         treesitter = {
    --           show_line = false,
    --           previewer = true,
    --         },
    --         colorscheme = {
    --           enable_preview = true,
    --         },
    --       },
    --       extensions = {
    --         fzf = {
    --           fuzzy = true,                   -- false will only do exact matching
    --           override_generic_sorter = true, -- override the generic sorter
    --           override_file_sorter = true,    -- override the file sorter
    --           case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
    --         },
    --         ["ui-select"] = {
    --           require("telescope.themes").get_dropdown({
    --             previewer = false,
    --             initial_mode = "normal",
    --             sorting_strategy = "ascending",
    --             layout_strategy = "horizontal",
    --             layout_config = {
    --               horizontal = {
    --                 width = 0.5,
    --                 height = 0.4,
    --                 preview_width = 0.6,
    --               },
    --             },
    --           }),
    --         },
    --       },
    --     })
    --
    -- end
    -- },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local builtin = require("telescope.builtin")
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local sorters = require("telescope.sorters")
            local from_entry = require("telescope.from_entry")

            -- Table pour stocker l'état des dossiers cachés par path
            local cd_state = {}

            -- Fonction principale Cd avec closure pour capturer l'état
            local function createCdFunction(initial_path, initial_show_hidden)
                return function()
                    local path = initial_path or "."
                    local show_hidden = initial_show_hidden or false

                    -- Stocker l'état pour ce path spécifique
                    cd_state[path] = show_hidden

                    local cmd = { "fd", ".", path, "-t", "d", "--ignore-file", vim.fn.expand(
                        "$HOME/.config/ignore/vim-ignore") }
                    if show_hidden then
                        table.insert(cmd, "-H")
                    end

                    local results = require("telescope.utils").get_os_command_output(cmd)

                    pickers.new({}, {
                        prompt_title = "Cd" .. (show_hidden and " (Hidden)" or ""),
                        finder = finders.new_table({
                            results = results,
                        }),
                        previewer = false,
                        sorter = sorters.get_fuzzy_file(),
                        attach_mappings = function(prompt_bufnr, map)
                            -- sélectionner dossier et changer cwd
                            actions.select_default:replace(function()
                                local entry = action_state.get_selected_entry()
                                actions.close(prompt_bufnr)
                                local dir = from_entry.path(entry)
                                vim.api.nvim_set_current_dir(dir)

                                vim.notify("Current directory: " .. dir,
                                vim.log.levels.INFO,
                                { title = "Directory changed" })
                            end)

                            -- Ctrl+h pour toggle les hidden files
                            local toggleHidden = function()
                                actions.close(prompt_bufnr)
                                createCdFunction(path, not show_hidden)()
                            end

                            map("i", "<C-h>", toggleHidden)
                            map("n", "<C-h>", toggleHidden)

                            return true
                        end,
                    }):find()
                end
            end

            local function multi_open(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()
                if #selections > 0 then
                    actions.close(prompt_bufnr)
                    for _, entry in ipairs(selections) do
                        local filename = entry.filename or entry.path
                        if filename then
                            vim.cmd("edit " .. vim.fn.fnameescape(filename))
                            if entry.lnum then
                                vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
                            end
                        end
                    end
                else
                    actions.select_default(prompt_bufnr)
                end
            end

            telescope.setup({
                defaults = {
                    file_ignore_patterns = { "%.git/", "node_modules", "package%-lock.json" },
                    path_display = { "filename_first" },
                    initial_mode = "insert",
                    select_strategy = "reset",
                    sorting_strategy = "ascending",
                    color_devicons = true,
                    set_env = { ["COLORTERM"] = "truecolor" },
                    layout_config = {
                        prompt_position = "top",
                        preview_cutoff = 120,
                    },
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                        -- Suivre les liens symboliques : les configs de ~/.config pointent
                        -- vers le dépôt dotfiles. Sans --follow, rg les ignore et <leader>fg
                        -- ne voit rien (mesuré dans ~/.config/nvim : 16 fichiers sans, 33 avec).
                        "--follow",
                        "--glob=!.git/",
                    },
                    mappings = {
                        i = {
                            ["<Tab>"]   = actions.toggle_selection + actions.move_selection_next,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
                            ["<CR>"]    = multi_open,
                            ["<C-h>"] = function(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                builtin.find_files({
                                    hidden = true,
                                    no_ignore = true,
                                    file_ignore_patterns = { "%.git/" },
                                })
                            end,
                        },
                        n = {
                            ["<Tab>"]   = actions.toggle_selection + actions.move_selection_next,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
                            ["<CR>"]    = multi_open,
                            ["<C-h>"] = function(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                builtin.find_files({
                                    hidden = true,
                                    no_ignore = true,
                                    file_ignore_patterns = { "%.git/" },
                                })
                            end,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        sort_mru = true,
                        -- Suivre les liens symboliques (dotfiles) et montrer les fichiers cachés
                        follow = true,
                        hidden = true,
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    live_grep = {
                        -- vimgrep_arguments contient déjà --follow ; ceci ne concerne
                        -- que la liste des fichiers parcourus par live_grep
                        follow = true,
                        hidden = true,
                    },
                    grep_string = {
                        follow = true,
                        hidden = true,
                    },
                    git_files = {
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    buffers = {
                        mappings = {
                            n = {
                                ["<Del>"] = actions.delete_buffer,
                                ["<BS>"] = actions.delete_buffer,
                                ["<Tab>"] = actions.select_default,
                            },
                        },
                        previewer = false,
                        initial_mode = "normal",
                        layout_config = {
                            height = 0.4,
                            width = 0.6,
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                        sort_mru = true,
                        ignore_current_buffer = true,
                    },
                    current_buffer_fuzzy_find = {
                        previewer = true,
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    lsp_references = {
                        show_line = false,
                        previewer = true,
                    },
                    treesitter = {
                        show_line = false,
                        previewer = true,
                    },
                    colorscheme = {
                        enable_preview = true,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({
                            previewer = false,
                            initial_mode = "normal",
                            sorting_strategy = "ascending",
                            layout_strategy = "horizontal",
                            layout_config = {
                                horizontal = {
                                    width = 0.5,
                                    height = 0.4,
                                    preview_width = 0.6,
                                },
                            },
                        }),
                    },
                },
            })

            -- ===== Keymaps =====
            -- vim.keymap.set("n", "<Leader>fd", createCdFunction(vim.fn.expand('$HOME'), false), { desc = "Cd into home" })
            -- pcall(vim.keymap.del, "n", "<C-f>")
            -- vim.keymap.set("n", "<C-f>", createCdFunction(vim.fn.expand('$HOME'), false), { desc = "Cd into home" })

            vim.defer_fn(function()
                local homeCd = createCdFunction(vim.fn.expand('$HOME'), false)
                -- vim.keymap.set("n", "<Leader>fd", homeCd, { desc = "Cd into home", noremap = true, silent = true })
                vim.keymap.set("n", "<C-f>", homeCd, { desc = "Cd into home", noremap = true, silent = true })
            end, 0)
        end,
    },

    -- {
    --     "nvim-tree/nvim-tree.lua",
    --     version = "*",
    --     lazy = false,
    --     requires = {
    --         "nvim-tree/nvim-web-devicons",
    --     },
    --     config = function()
    --         require("nvim-tree").setup {
    --             sort = { sorter = "case_sensitive" },
    --             view = {
    --                 width = 30,
    --                 adaptive_size = true,
    --             },
    --             renderer = { group_empty = true },
    --             filters = { dotfiles = false },
    --         }
    --     end,
    -- },

    -- Désactivé : plus utilisé, et c'est lui qui réclamait le trousseau de clés
    -- (son jeton d'authentification y est stocké) à chaque ouverture de nvim.
    -- Pour le réactiver : décommenter, puis :Lazy sync
    -- {
    --     "github/copilot.vim",
    --     config = function()
    --         vim.cmd("Copilot disable")
    --     end,
    -- },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,

        config = function()
            -- attention, c'est moi qui est modifié à la main le code source pour pouvoir rajouter la ligne ["<cr>"] = "open",
            -- dans le fichier "neo-tree.nvim/lua/neo-tree/sources/filesystem/lib/filter.lua", après la fonction 
            --     close_clear_filter = function(_state, _scroll_padding)
            --[[ 

            open = function(state_)
                local fs_cmds = require("neo-tree.sources.filesystem.commands")
                local utils = require("neo-tree.utils")

                -- Récupère le buffer actif avant d'ouvrir
                local bufnr_before = vim.api.nvim_get_current_buf()

                -- Appelle la commande native open de Neo-tree
                fs_cmds.open(state_)

                -- Récupère le buffer actif après ouverture
                local bufnr_after = vim.api.nvim_get_current_buf()

                -- Supprime les buffers No Name laissés derrière
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_get_name(b) == "" and b ~= bufnr_after then
                        vim.api.nvim_buf_delete(b, { force = true })
                    end
                end
            end

            ]]

            -- Ajout de la configuration pour les événements de déplacement/renommage
            local function on_move(data)
                Snacks.rename.on_rename_file(data.source, data.destination)
            end
            local events = require("neo-tree.events")

            require("neo-tree").setup({
                -- Affiche la cible des liens symboliques.
                -- Le composant existe déjà dans le renderer par défaut de neo-tree,
                -- il est simplement désactivé d'origine.
                default_component_configs = {
                    symlink_target = {
                        enabled = true,
                    },
                },

                window = {
                    position = "left",
                    width = 40,
                    mappings = {
                      ["<space>"] = {
                        "toggle_node",
                        nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
                      },
                      ["<2-LeftMouse>"] = "open",
                      ["<cr>"] = "open",
                      ["<esc>"] = "cancel", -- close preview or floating neo-tree window
                      ["P"] = {
                        "toggle_preview",
                        config = {
                          use_float = true,
                          use_snacks_image = true,
                          use_image_nvim = true,
                        },
                      },

                      ['<C-Left>'] = "navigate_up";
                      ['<C-Right>'] = "set_root";

                      -- Read `# Preview Mode` for more information
                      -- ["l"] = "focus_preview",
                      ["S"] = "open_split",
                      ["s"] = "open_vsplit",
                      ["t"] = "open_tabnew",
                      -- ["t"] = "open_tab_drop",
                      ["w"] = "open_with_window_picker",
                      --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
                      ["C"] = "close_node",
                      ["<Left>"] = "close_node",
                      ["h"] = "close_node",
                      -- ['C'] = 'close_all_subnodes',
                      ["z"] = "close_all_nodes",
                      --["Z"] = "expand_all_nodes",
                      --["Z"] = "expand_all_subnodes",

                      ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
                      ["d"] = "delete",
                      ["r"] = "rename",
                      ["b"] = "rename_basename",
                      ["y"] = "copy_to_clipboard",
                      ["x"] = "cut_to_clipboard",
                      ["p"] = "paste_from_clipboard",
                      ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
                      -- ["c"] = {
                      --  "copy",
                      --  config = {
                      --    show_path = "none" -- "none", "relative", "absolute"
                      --  }
                      --}
                      ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
                      ["q"] = "close_window",
                      ["R"] = "refresh",
                      ["?"] = "show_help",
                      ["<"] = "prev_source",
                      [">"] = "next_source",
                      ["i"] = "show_file_details",

                      ["<Tab>"] = function(state)
                          local node = state.tree:get_node()
                          if not node then return end

                          local api = vim.api
                          local tree_win = api.nvim_get_current_win() -- fenêtre Neo-tree
                          local main_win

                          -- trouver la première fenêtre qui n'est pas Neo-tree
                          for _, win in ipairs(api.nvim_list_wins()) do
                              if win ~= tree_win then
                                  main_win = win
                                  break
                              end
                          end

                          if node.type == "file" and main_win then
                              -- ouvrir le fichier dans la fenêtre principale
                              api.nvim_win_call(main_win, function()
                                  vim.cmd.edit({ args = { node.path }, mods = { silent = true, keepalt = true } })
                              end)
                          elseif node.type == "directory" then
                              -- ouvrir le dossier dans Neo-tree normalement
                              require("neo-tree.sources.filesystem.commands").open(state)
                          end
                      end,

                      ["<Right>"] = function(state)
                          local node = state.tree:get_node()
                          if not node then return end

                          local api = vim.api
                          local tree_win = api.nvim_get_current_win() -- fenêtre Neo-tree
                          local main_win

                          -- trouver la première fenêtre qui n'est pas Neo-tree
                          for _, win in ipairs(api.nvim_list_wins()) do
                              if win ~= tree_win then
                                  main_win = win
                                  break
                              end
                          end

                          if node.type == "file" and main_win then
                              -- ouvrir le fichier dans la fenêtre principale
                              api.nvim_win_call(main_win, function()
                                  vim.cmd.edit({ args = { node.path }, mods = { silent = true, keepalt = true } })
                              end)
                          elseif node.type == "directory" then
                              -- ouvrir le dossier dans Neo-tree normalement
                              require("neo-tree.sources.filesystem.commands").open(state)
                          end
                      end,

                      ["l"] = function(state)
                          local node = state.tree:get_node()
                          if not node then return end

                          local api = vim.api
                          local tree_win = api.nvim_get_current_win() -- fenêtre Neo-tree
                          local main_win

                          -- trouver la première fenêtre qui n'est pas Neo-tree
                          for _, win in ipairs(api.nvim_list_wins()) do
                              if win ~= tree_win then
                                  main_win = win
                                  break
                              end
                          end

                          if node.type == "file" and main_win then
                              -- ouvrir le fichier dans la fenêtre principale
                              api.nvim_win_call(main_win, function()
                                  vim.cmd.edit({ args = { node.path }, mods = { silent = true, keepalt = true } })
                              end)
                          elseif node.type == "directory" then
                              -- ouvrir le dossier dans Neo-tree normalement
                              require("neo-tree.sources.filesystem.commands").open(state)
                          end
                      end,

                    },
                  },
                  nesting_rules = {},
                  filesystem = {
                    filtered_items = {

                      visible = false, -- when true, they will just be displayed differently than normal items
                      hide_dotfiles = true,
                      hide_gitignored = true,
                      hide_ignored = true, -- hide files that are ignored by other gitignore-like files
                      -- other gitignore-like files, in descending order of precedence.
                      ignore_files = {
                        ".neotreeignore",
                        ".ignore",
                        -- ".rgignore"
                      },
                      hide_hidden = true, -- only works on Windows for hidden files/directories
                      hide_by_name = {
                        --"node_modules"
                      },
                      hide_by_pattern = { -- uses glob style patterns
                        --"*.meta",
                        --"*/src/*/tsconfig.json",
                      },
                      always_show = { -- remains visible even if other settings would normally hide it
                        --".gitignored",
                      },
                      always_show_by_pattern = { -- uses glob style patterns
                        --".env*",
                      },
                      never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                        --".DS_Store",
                        --"thumbs.db"
                      },
                      never_show_by_pattern = { -- uses glob style patterns
                        --".null-ls_*",
                      },
                    },
                    follow_current_file = {
                      enabled = true, -- This will find and focus the file in the active buffer every time
                      --               -- the current file is changed while the tree is open.
                      leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                    },
                    group_empty_dirs = false, -- when true, empty folders will be grouped together
                    hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                    -- in whatever position is specified in window.position
                    -- "open_current",  -- netrw disabled, opening a directory opens within the
                    -- window like netrw would, regardless of window.position
                    -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
                    use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
                    -- instead of relying on nvim autocmd events.
                    window = {
                      mappings = {
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
                        -- ["D"] = "fuzzy_sorter_directory",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified",
                        ["o"] = {
                          "show_help",
                          nowait = false,
                          config = { title = "Order by", prefix_key = "o" },
                        },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["og"] = { "order_by_git_status", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                        -- ['<key>'] = function(state) ... end,
                      },
                      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
                        ["<cr>"] = "open", --<<<------------------------------------------- COMMANDE PERSO (cf commentaire plus haut)
                        ["<down>"] = "move_cursor_down",
                        ["<C-n>"] = "move_cursor_down",
                        ["<up>"] = "move_cursor_up",
                        ["<C-p>"] = "move_cursor_up",
                        ["<esc>"] = "close",
                        ["<S-CR>"] = "close_keep_filter",
                        ["<C-CR>"] = "close_clear_filter",
                        ["<C-w>"] = { "<C-S-w>", raw = true },
                        {
                          -- normal mode mappings
                          n = {
                            ["j"] = "move_cursor_down",
                            ["k"] = "move_cursor_up",
                            ["<S-CR>"] = "close_keep_filter",
                            ["<C-CR>"] = "close_clear_filter",
                            ["<esc>"] = "close",
                          }
                        }
                        -- ["<esc>"] = "noop", -- if you want to use normal mode
                        -- ["key"] = function(state, scroll_padding) ... end,
                      },
                    },

                    commands = {
                        -- Create open command for visual mode (currently missing)
                        open_visual = function(state, selected_nodes)
                            local utils = require 'neo-tree.utils'
                            if not selected_nodes or #selected_nodes == 0 then
                                vim.notify('No files selected', vim.log.levels.WARN, { title = 'Neo-tree' })

                                return
                            end

                            for _, node in ipairs(selected_nodes) do
                                if node.type == 'file' then
                                    local path = node.path or node:get_id()
                                    local bufnr = node.extra and node.extra.bufnr
                                    -- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/0d0b29a529216d41173c9c5c8a8f484db5b891ba/lua/neo-tree/sources/common/commands.lua#L819
                                    -- TODO: Experiment with splits
                                    utils.open_file(state, path, 'e', bufnr)
                                end
                            end
                            vim.cmd 'Neotree close'
                        end,
                    },
                  },

                  event_handlers = {
                      { event = events.FILE_MOVED, handler = on_move },
                      { event = events.FILE_RENAMED, handler = on_move },
                  }

            })

            -- Raccourcit la cible affichée pour un lien symbolique.
            -- neo-tree rend UNE ligne par fichier : impossible d'y mettre un retour à la
            -- ligne, on abrège donc le chemin plutôt que de l'afficher en entier.
            --   avant : ➛ /home/for/Documents/programming/github-noforest/dotfiles/modules/nvim/.config/nvim/lua/plugins/lazy.lua
            --   après : ➛ dotfiles:…/plugins/lazy.lua
            --
            -- L'assignation se fait sur le module lui-même : setup() écrase la clé
            -- `components` de la config source par ce module (setup/init.lua:537),
            -- donc la passer dans la config utilisateur ne fonctionne pas.
            local fs_components = require("neo-tree.sources.filesystem.components")
            fs_components.symlink_target = function(config, node, _)
                if not node.is_link then
                    return {}
                end
                local target = node.link_to or ""
                local dot = vim.env.DOTFILES_DIR
                    or (vim.env.HOME .. "/Documents/programming/github-noforest/dotfiles")
                local label
                if target:sub(1, #dot) == dot then
                    local parts = vim.split(target:sub(#dot + 2), "/", { plain = true })
                    label = "dotfiles:"
                        .. (#parts > 2
                            and ("…/" .. parts[#parts - 1] .. "/" .. parts[#parts])
                            or table.concat(parts, "/"))
                else
                    label = target:gsub("^" .. vim.pesc(vim.env.HOME), "~")
                    local parts = vim.split(label, "/", { plain = true })
                    if #parts > 4 then
                        label = parts[1] .. "/…/" .. parts[#parts - 1] .. "/" .. parts[#parts]
                    end
                end
                return {
                    text = " ➛ " .. label,
                    highlight = config.highlight or "NeoTreeSymbolicLinkTarget",
                }
            end
        end,
    },

    -- lazy.nvim
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {},
    },


    -- {
    --     'akinsho/bufferline.nvim',
    --     version = "*",
    --     dependencies = 'nvim-tree/nvim-web-devicons',
    -- },
    -- NOTE: BUFFERS en haut de la fenêtre
    {
        "romgrk/barbar.nvim",
        dependencies = {
            'lewis6991/gitsigns.nvim',
            "nvim-tree/nvim-web-devicons",
        },
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {
            animation = false,
            auto_hide = false,
            clickable = true,

            insert_at_end = false,
            insert_at_start = false,

            focus_on_close = "left",

            icons = {

                buffer_index = false,
                buffer_number = false,
                -- Enables / disables diagnostic symbols
                diagnostics = {
                    [vim.diagnostic.severity.ERROR] = {enabled = true},
                    [vim.diagnostic.severity.WARN] = {enabled = false},
                    [vim.diagnostic.severity.INFO] = {enabled = false},
                    [vim.diagnostic.severity.HINT] = {enabled = false},
                },
                -- gitsigns = {
                --     added = {enabled = true, icon = '+'},
                --     changed = {enabled = true, icon = '~'},
                --     deleted = {enabled = true, icon = '-'},
                -- },
                separator = { left = "▎", right = "" },
                separator_at_end = false,
                -- modified = { button = "" }, -- 
                modified = { button = "󰝥" }, -- 
                pinned = {button = '', filename = true},
                -- button = "×",
                button = '',

            },
            highlight_inactive_file_icons = true,

            sort = {
                ignore_case = true,
            },
        },
        config = function(_, opts)
            require("barbar").setup(opts)

            local function set_highlights()
                vim.api.nvim_set_hl(0, "BufferCurrent",           { bold = true })
                vim.api.nvim_set_hl(0, "BufferInactive",           { bg = "#11111b", fg = "#6c7086"})
                vim.api.nvim_set_hl(0, "BufferVisible",           { bg = "#11111b", fg = "#6c7086"})
                vim.api.nvim_set_hl(0, "BufferCurrentMod",        { bg = "#181825", fg="#cdd6f4", bold = true })
                vim.api.nvim_set_hl(0, "BufferInactiveMod",       { bg = "#11111b", fg = "#6c7086" })
                vim.api.nvim_set_hl(0, "BufferVisibleMod",        { bg = "#11111b", fg = "#6c7086"})
                vim.api.nvim_set_hl(0, "BufferCurrentERROR",      { bg = "#181825", fg = "#f38ba8"})
                vim.api.nvim_set_hl(0, "BufferCurrentWARN",      { bg = "#181825", fg = "#f9e2af" })
                vim.api.nvim_set_hl(0, "BufferCurrentINFO",       { bg = "#181825", fg = "#89dceb" })
                vim.api.nvim_set_hl(0, "BufferCurrentHINT",       { bg = "#181825", fg = "#94e2d5" })

                vim.api.nvim_set_hl(0, "BufferCurrentAdded",   { bg = "#181825", fg = "#a6e3a1" })
                vim.api.nvim_set_hl(0, "BufferCurrentChanged", { bg = "#181825", fg = "#f9e2af" })
                vim.api.nvim_set_hl(0, "BufferCurrentDeleted", { bg = "#181825", fg = "#f38ba8" })
                vim.api.nvim_set_hl(0, "BufferCurrentModBtn",  { fg = "#a6e3a1", bold = true })
                vim.api.nvim_set_hl(0, "BufferInactiveModBtn", { fg = "#a6e3a1" })
                vim.api.nvim_set_hl(0, "BufferVisibleModBtn",  { fg = "#a6e3a1" })
            end

            set_highlights()
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = set_highlights,
            })

            -- NOTE: Exclure les buffers codediff de barbar
            -- vim.api.nvim_create_autocmd("BufAdd", {
            --     callback = function(ev)
            --         local name = vim.api.nvim_buf_get_name(ev.buf)
            --         if name:match("codediff:///*") or name:match("%x%x%x%x%x%x%x") then
            --             vim.bo[ev.buf].buflisted = false
            --         end
            --     end,
            -- })
        end,
    },

    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            focus = true,
            keys = {
                ["q"] = "close",
                ["<esc>"] = "close",
            },
        },
    },
    -- {
    --   "3rd/image.nvim",
    --   opts = {
    --     backend = "kitty",
    --     integrations = {
    --       markdown = {
    --         enabled = true,
    --         clear_in_insert_mode = false,
    --         download_remote_images = true,
    --         only_render_image_at_cursor = false,
    --         filetypes = { "markdown", "vimwiki" },
    --       },
    --     },
    --     max_width = 100,
    --     max_height = 12,
    --     max_width_window_percentage = math.huge,
    --     max_height_window_percentage = math.huge,
    --
    --     -- CONFIGURATION POUR ÉVITER LA DISPARITION AVEC BLINK.CMP :
    --     window_overlap_clear_enabled = false, -- Empêche d'effacer l'image quand une popup s'ouvre
    --     window_overlap_clear_ft_ignore = { 
    --       "cmp_menu", 
    --       "cmp_docs", 
    --       "blink-cmp-documentation", 
    --       "blink-cmp-menu", 
    --       "" 
    --     },
    --   },
    -- },

    -- {
    --     "karb94/neoscroll.nvim",
    --     config = function()
    --         require('neoscroll').setup({
    --             mappings = { -- Keys to be mapped to their corresponding default scrolling animation
    --                 '<C-u>', '<C-d>',
    --                 '<C-b>', '<C-f>',
    --                 '<C-y>', '<C-e>',
    --                 -- 'zt', 'zz', 'zb',
    --             },
    --             hide_cursor = false,         -- Hide cursor while scrolling
    --             stop_eof = true,             -- Stop at <EOF> when scrolling downwards
    --             respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
    --             cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
    --             easing = 'linear',           -- Default easing function
    --             pre_hook = nil,              -- Function to run before the scrolling animation starts
    --             post_hook = nil,             -- Function to run after the scrolling animation ends
    --             performance_mode = false,    -- Disable "Performance Mode" on all buffers.
    --             duration_multiplier = 0.5,   -- plus rapide
    --             ignored_events = {           -- Events ignored while scrolling
    --                 'WinScrolled', 'CursorMoved'
    --             },
    --         })
    --     end
    -- },

    -- {
    --     'mg979/vim-visual-multi',
    --     config = function()
    --         vim.g.VM_show_warnings = 0
    --         vim.g.VM_silent_exit = 1
    --     end
    -- },
    -- lazy.nvim:
    -- {
    --     "smoka7/multicursors.nvim",
    --     event = "VeryLazy",
    --     dependencies = {
    --         'nvimtools/hydra.nvim',
    --     },
    --     opts = {},
    --     cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
    --     keys = {
    --         {
    --             mode = { 'v', 'n' },
    --             '<Leader>m',
    --             '<cmd>MCstart<cr>',
    --             desc = 'Create a selection for selected text or word under the cursor',
    --         },
    --     },
    -- },
    {
        "jake-stewart/multicursor.nvim",
        branch = "1.0",
        config = function()
            local mc = require("multicursor-nvim")
            mc.setup()

            local set = vim.keymap.set

            -- Add or skip cursor above/below the main cursor.
            -- set({"n", "x"}, "<up>", function() mc.lineAddCursor(-1) end)
            -- set({"n", "x"}, "<down>", function() mc.lineAddCursor(1) end)
            -- set({"n", "x"}, "<leader><up>", function() mc.lineSkipCursor(-1) end)
            -- set({"n", "x"}, "<leader><down>", function() mc.lineSkipCursor(1) end)

            -- Add or skip adding a new cursor by matching word/selection
            set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end)
            set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end)

            set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end)
            set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end)

            -- Add and remove cursors with control + left click.
            set("n", "<c-leftmouse>", mc.handleMouse)
            set("n", "<c-leftdrag>", mc.handleMouseDrag)
            set("n", "<c-leftrelease>", mc.handleMouseRelease)

            -- Disable and enable cursors.
            set({ "n", "x" }, "<c-q>", mc.toggleCursor)

            -- Mappings defined in a keymap layer only apply when there are
            -- multiple cursors. This lets you have overlapping mappings.
            mc.addKeymapLayer(function(layerSet)
                -- Select a different cursor as the main one.
                layerSet({ "n", "x" }, "<left>", mc.prevCursor)
                layerSet({ "n", "x" }, "<right>", mc.nextCursor)

                -- Delete the main cursor.
                layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

                -- Enable and clear cursors using escape.
                layerSet("n", "<esc>", function()
                    if not mc.cursorsEnabled() then
                        mc.enableCursors()
                    else
                        mc.clearCursors()
                    end
                end)
            end)

            -- Customize how cursors look.
            local hl = vim.api.nvim_set_hl
            hl(0, "MultiCursorCursor", { link = "Cursor" })
            hl(0, "MultiCursorVisual", { link = "Visual" })
            hl(0, "MultiCursorSign", { link = "SignColumn" })
            hl(0, "MultiCursorMatchPreview", { link = "Search" })
            hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
            hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
            hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
        end
    },


    -- {
    --     'arminveres/md-pdf.nvim',
    --     branch = 'main', -- you can assume that main is somewhat stable until releases will be made
    --     lazy = true,
    --     keys = {
    --         {
    --             "ùll",
    --             function() require("md-pdf").convert_md_to_pdf() end,
    --             desc = "Markdown preview",
    --         },
    --     },
    --     ---@type md-pdf.config
    --     opts = {
    --         -- Generate a table of contents, on by default
    --         toc = false,
    --         preview_cmd = function() return 'zathura' end,
    --         margins = "1.3cm",
    --     },
    -- },

    {
        'arminveres/md-pdf.nvim',
        branch = 'main',
        lazy = true,
        init = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function()
                    vim.keymap.set("n", "ùll", function()
                        require("md-pdf").convert_md_to_pdf()
                    end, { desc = "Markdown preview", buffer = true })
                end,
            })
        end,
        opts = {
            toc = false,
            preview_cmd = function() return 'zathura' end,
            margins = "1.3cm",
        },
    },

    {
        'MeanderingProgrammer/render-markdown.nvim',
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons', '3rd/image.nvim' },
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },

        opts = {
            heading = {
                enabled = false,
                width = 'block',
                sign = false,
            },
            code = {
                enabled = true,
                width = 'block',
                sign = false,
            },
            image = {
                enabled = false,
            },

        },
    },


    {
        'numToStr/Comment.nvim',
        opts = {
            pre_hook = function()
                if vim.bo.filetype == 'tex' then
                    return '% %s'
                end
                -- Sans parser Treesitter pour le buffer, Comment.ft.calculate()
                -- appelle parser:lang() sur un nil (nvim >= 0.11 renvoie nil au lieu
                -- de lever une erreur) : gcc/gbc échouent en silence. Cas concret :
                -- filetype zsh (.zshrc, .zshenv, .p10k.zsh) — aucun parser zsh installé.
                -- On retombe alors sur le 'commentstring' du buffer.
                if not vim.treesitter.get_parser(0, nil, { error = false }) then
                    return vim.bo.commentstring
                end
            end,
        }
    },

    -- {
    --     "lervag/vimtex",
    --     lazy = false, -- we don't want to lazy load VimTeX
    --     -- tag = "v2.15", -- uncomment to pin to a specific release
    --     init = function()
    --         -- VimTeX configuration goes here, e.g.
    --         vim.g.vimtex_view_method = "zathura"
    --         vim.g.maplocalleader = "ù"
    --         vim.g.vimtex_quickfix_mode = 0 -- enlève la fenêtre de warning à chaque fois que je compile.
    --     end
    -- },

    {
        -- IMPORTANT: faire: ':h vimtex' et aller dans default mapping
        -- --------------------------------------------------------------------- ~
       --  LHS              RHS                                          MODE ~
       --  -------------------------------------------------------------------- ~
       --  <localleader>li  |<plug>(vimtex-info)|                           `n`
       --  <localleader>lI  |<plug>(vimtex-info-full)|                      `n`
       --  <localleader>lt  |<plug>(vimtex-toc-open)|                       `n`
       --  <localleader>lT  |<plug>(vimtex-toc-toggle)|                     `n`
       --  <localleader>lq  |<plug>(vimtex-log)|                            `n`
       --  <localleader>lv  |<plug>(vimtex-view)|                           `n`
       --  <localleader>lr  |<plug>(vimtex-reverse-search)|                 `n`

        "lervag/vimtex",
        lazy = false, -- on ne veut pas charger VimTeX en lazy
        -- tag = "v2.15", -- décommente si tu veux figer la version
        init = function()
            -- Configuration de base
            vim.g.vimtex_view_method = "zathura"
            vim.g.maplocalleader = "ù"
            vim.g.vimtex_quickfix_mode = 0 -- enlève la fenêtre de warning à chaque compilation

            -- ajouter pour gagner nettement de la performance
            vim.g.vimtex_complete_enabled = 0
            vim.g.vimtex_syntax_enabled = 1
            vim.g.vimtex_syntax_conceal_disable = 1
            vim.g.vimtex_indent_enabled = 0

            -- --- Compilateur par défaut : PdfLaTeX ---
            vim.g.vimtex_compiler_method = "latexmk"
            vim.g.vimtex_compiler_latexmk = {
                aux_dir = '_latex_aux',
                out_dir = '_latex_output',
                callback = 1,
                continuous = 1,
                executable = 'latexmk',
                options = {
                    '-pdf', -- compile avec pdflatex par défaut
                    '-interaction=nonstopmode',
                    '-synctex=1',
                },
            }
        end
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            highlight = {
                backdrop = false,
                matches = false,
            },
            modes = {
                char = {
                    highlight = { 
                        backdrop = false,
                        matches = false,
                    },
                    keys = { "f", "F", ";", "," },
                },
            },
        },
        config = function(_, opts)
            local flash = require("flash")
            flash.setup(opts)

            local search_hl = vim.api.nvim_get_hl(0, { name = "Search" })

            vim.api.nvim_set_hl(0, "FlashLabel", { bg = search_hl.bg, fg = "NONE" })
            vim.api.nvim_set_hl(0, "FlashBackdrop", {})
            vim.api.nvim_set_hl(0, "FlashMatch", {})
            vim.api.nvim_set_hl(0, "FlashCurrent", {})
        end,
    },


    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,  -- le README dit explicitement no lazy loading
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter').setup({
                install_dir = vim.fn.stdpath('data') .. '/site',
            })

            require('nvim-treesitter').install({
                'lua', 'python', 'bash', 'markdown', 'markdown_inline',
                'javascript', 'c', 'cpp', 'vim', 'vimdoc', 'query', 'rust',
                'typescript', 'java', 'zsh', 'git_config'
            })

            vim.api.nvim_create_autocmd('FileType', {
                callback = function(args)
                    local buf, filetype = args.buf, args.match
                    local language = vim.treesitter.language.get_lang(filetype)
                    if not language then return end
                    local ok = pcall(vim.treesitter.language.add, language)
                    if not ok then return end
                    pcall(vim.treesitter.start, buf, language)
                end,
            })
        end,
    },


    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {
                signs = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '—' },
                    topdelete = { text = '—' },
                    changedelete = { text = '~' },
                },
                signs_staged = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '—' },
                    topdelete = { text = '—' },
                    changedelete = { text = '~' },
                },
            }
        end,

    },
    -- {
    --     "esmuellert/codediff.nvim",
    --     dependencies = { "MunifTanjim/nui.nvim" },
    --     cmd = "CodeDiff",
    --     opts = {
    --
    --         -- Explorer panel configuration
    --         explorer = {
    --             position = "bottom",  -- "left" or "bottom"
    --             width = 30,         -- Width when position is "left" (columns)
    --             height = 7,        -- Height when position is "bottom" (lines)
    --             indent_markers = true,  -- Show indent markers in tree view (│, ├, └)
    --             initial_focus = "modified",  -- Initial focus: "explorer", "original", or "modified"
    --             icons = {
    --                 folder_closed = "",  -- Nerd Font folder icon (customize as needed)
    --                 folder_open = "",    -- Nerd Font folder-open icon
    --             },
    --             view_mode = "tree",    -- "list" or "tree"
    --             file_filter = {
    --                 ignore = {},  -- Glob patterns to hide (e.g., {"*.lock", "dist/*"})
    --             },
    --         },
    --
    --         -- History panel configuration (for :CodeDiff history)
    --         history = {
    --             position = "bottom",  -- "left" or "bottom" (default: bottom)
    --             width = 40,           -- Width when position is "left" (columns)
    --             height = 7,          -- Height when position is "bottom" (lines)
    --             initial_focus = "modified",  -- Initial focus: "history", "original", or "modified"
    --             view_mode = "list",   -- "list" or "tree" for files under commits
    --         },
    --
    --         -- Keymaps in diff view
    --         keymaps = {
    --             view = {
    --                 quit = "q",                    -- Close diff tab
    --                 toggle_explorer = "<leader>b",  -- Toggle explorer visibility (explorer mode only)
    --
    --                 next_hunk = "<Right>",   -- Jump to next change
    --                 prev_hunk = "<Left>",   -- Jump to previous change
    --                 -- next_hunk = "<Down>",   -- Jump to next change
    --                 -- prev_hunk = "<Up>",   -- Jump to previous change
    --
    --                 -- next_file = "]f",   -- Next file in explorer/history mode
    --                 -- prev_file = "[f",   -- Previous file in explorer/history mode
    --                 next_file = "<Tab>",
    --                 prev_file = "<S-Tab>",
    --                 diff_get = "do",    -- Get change from other buffer (like vimdiff)
    --                 diff_put = "dp",    -- Put change to other buffer (like vimdiff)
    --                 open_in_prev_tab = "gf", -- Open current buffer in previous tab (or create one before)
    --             },
    --         }
    --     }
    -- },

    {
        -- IMPORTANT: C'est MON PLUGIN LOCAL: codediff_milestone_noah
        dir = vim.fn.expand("~/.config/nvim/plugins/codediff_milestone_noah"),
        name = "codediff",
        dependencies = { "MunifTanjim/nui.nvim" },
        cmd = "CodeDiff",
        opts = {

            -- Explorer panel configuration
            explorer = {
                position = "bottom",  -- "left" or "bottom"
                width = 30,         -- Width when position is "left" (columns)
                height = 7,        -- Height when position is "bottom" (lines)
                indent_markers = true,  -- Show indent markers in tree view (│, ├, └)
                initial_focus = "modified",  -- Initial focus: "explorer", "original", or "modified"
                icons = {
                    folder_closed = "",  -- Nerd Font folder icon (customize as needed)
                    folder_open = "",    -- Nerd Font folder-open icon
                },
                view_mode = "tree",    -- "list" or "tree"
                file_filter = {
                    ignore = {},  -- Glob patterns to hide (e.g., {"*.lock", "dist/*"})
                },
            },

            -- History panel configuration (for :CodeDiff history)
            history = {
                position = "bottom",  -- "left" or "bottom" (default: bottom)
                width = 40,           -- Width when position is "left" (columns)
                height = 7,          -- Height when position is "bottom" (lines)
                initial_focus = "modified",  -- Initial focus: "history", "original", or "modified"
                view_mode = "list",   -- "list" or "tree" for files under commits
            },

            -- Keymaps in diff view
            keymaps = {
                view = {
                    quit = "q",                    -- Close diff tab
                    toggle_explorer = "<leader>b",  -- Toggle explorer visibility (explorer mode only)

                    next_hunk = "<Right>",   -- Jump to next change
                    prev_hunk = "<Left>",   -- Jump to previous change
                    -- next_hunk = "<Down>",   -- Jump to next change
                    -- prev_hunk = "<Up>",   -- Jump to previous change

                    -- next_file = "]f",   -- Next file in explorer/history mode
                    -- prev_file = "[f",   -- Previous file in explorer/history mode
                    next_file = "<Tab>",
                    prev_file = "<S-Tab>",
                    diff_get = "do",    -- Get change from other buffer (like vimdiff)
                    diff_put = "dp",    -- Put change to other buffer (like vimdiff)
                    open_in_prev_tab = "gf", -- Open current buffer in previous tab (or create one before)
                },
            }
        }
    },

    -- {
    --     "sindrets/diffview.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    --     config = function()
    --         local actions = require("diffview.actions")
    --         require("diffview").setup({
    --             diff_binaries = false,
    --             enhanced_diff_hl = false,
    --             git_cmd = { "git" },
    --             use_icons = true,
    --             show_help_hints = false,
    --             watch_index = true,
    --             icons = {
    --                 folder_closed = "",
    --                 folder_open = "",
    --             },
    --             signs = {
    --                 fold_closed = "",
    --                 fold_open = "",
    --                 done = "✓",
    --             },
    --             view = {
    --                 default = {
    --                     layout = "diff2_horizontal",
    --                     disable_diagnostics = false,
    --                     winbar_info = false,
    --                 },
    --                 merge_tool = {
    --                     layout = "diff3_horizontal",
    --                     disable_diagnostics = true,
    --                     winbar_info = true,
    --                 },
    --                 file_history = {
    --                     layout = "diff2_horizontal",
    --                     disable_diagnostics = false,
    --                     winbar_info = false,
    --                 },
    --             },
    --             file_panel = {
    --                 listing_style = "tree",
    --                 tree_options = {
    --                     flatten_dirs = true,
    --                     folder_statuses = "only_folded",
    --                 },
    --                 win_config = {
    --                     position = "bottom",  -- bottom
    --                     height = 7,
    --                     win_opts = {},
    --                 },
    --             },
    --             file_history_panel = {
    --                 log_options = {
    --                     git = {
    --                         single_file = { diff_merges = "combined" },
    --                         multi_file = { diff_merges = "first-parent" },
    --                     },
    --                 },
    --                 win_config = {
    --                     position = "bottom",
    --                     height = 7,
    --                     win_opts = {},
    --                 },
    --             },
    --             hooks = {
    --                 diff_buf_win_enter = function(bufnr, winid, ctx)
    --                     -- Focus le côté droit (modified)
    --                     if ctx.layout_name:match("^diff2") and ctx.symbol == "b" then
    --                         vim.schedule(function()
    --                             vim.api.nvim_set_current_win(winid)
    --                         end)
    --                     end
    --                 end,
    --             },
    --             keymaps = {
    --                 disable_defaults = false,
    --                 view = {
    --                     { "n", "q",         actions.close,             { desc = "Close diff tab" } },
    --                     { "n", "<leader>b", actions.toggle_files,      { desc = "Toggle file panel" } },
    --                     { "n", "<Right>", "]c", { desc = "Next hunk" } },
    --                     { "n", "<Left>",  "[c", { desc = "Previous hunk" } },
    --                     { "n", "<Tab>",     actions.select_next_entry, { desc = "Next file" } },
    --                     { "n", "<S-Tab>",   actions.select_prev_entry, { desc = "Previous file" } },
    --                     { "n", "do",        actions.diffget,           { desc = "Get change from other buffer" } },
    --                     { "n", "dp",        actions.diffput,           { desc = "Put change to other buffer" } },
    --                     { "n", "gf",        actions.goto_file_edit,    { desc = "Open in previous tab" } },
    --                 },
    --                 file_history_panel = {
    --                     { "n", "q",         actions.close,             { desc = "Close diff tab" } },
    --                     { "n", "<leader>b", actions.toggle_files,      { desc = "Toggle file panel" } },
    --                     { "n", "<Right>", "]c", { desc = "Next hunk" } },
    --                     { "n", "<Left>",  "[c", { desc = "Previous hunk" } },
    --                     { "n", "<Tab>",     actions.select_next_entry, { desc = "Next file" } },
    --                     { "n", "<S-Tab>",   actions.select_prev_entry, { desc = "Previous file" } },
    --                     { "n", "gf",        actions.goto_file_edit,    { desc = "Open in previous tab" } },
    --                 },
    --             },
    --         })
    --         vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#444444" })
    --     end,
    -- },

    {'akinsho/git-conflict.nvim', version = "*", config = true},

    {
        "NeogitOrg/neogit",
        lazy = true,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "codediff",
            "folke/snacks.nvim",
            "rbong/vim-flog",
        },
        cmd = "Neogit",
        keys = {
            { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
        },
        opts = {
            status = {
                show_head_commit_hash = true,
                -- recent_commit_count = 1000000,
                recent_commit_count = 15,
                HEAD_padding = 10,
                HEAD_folded = false,
                mode_padding = 1,
            },

            graph_style = "unicode",
            sections = {
                recent = {
                    folded = false,
                    hidden = false,
                },
            },

            mappings = {
                status = {
                    ["<Right>"] = "GoToFile",
                    ["<Left>"] = "Close",
                    -- ["<Tab>"] = false,
                },
                finder = {
                    -- ["<Tab>"] = false,
                }
            }
        }
    },


    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = 'auto',
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                    disabled_filetypes = {
                        statusline = { "NvimTree", "neo-tree" },
                        winbar = { "NvimTree", "neo-tree" },
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    always_show_tabline = true,
                    globalstatus = false,
                    refresh = {
                        statusline = 10,
                        tabline = 10,
                        winbar = 10,
                    }
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = { 'branch', 'diff', 'diagnostics' },
                    lualine_c = {
                        {
                            'filename',
                            path = 1, -- Affiche le chemin relatif
                        }
                    },
                    lualine_x = { 'encoding', 'fileformat', 'filetype' },
                    lualine_y = { 'progress' },
                    lualine_z = { 'location' }
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {
                        {
                            'filename',
                            path = 1, -- Affiche le chemin relatif
                        }
                    },
                    lualine_x = { 'location' },
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                extensions = {}
            }
        end,
    },


    -- {"ggandor/leap.nvim"}, -- qd je serai un vim-experienced guy

    -- {
    --   "leath-dub/snipe.nvim",
    --   keys = {
    --     {
    --       "<leader><Tab>",
    --       function()
    --         require("snipe").open_buffer_menu()
    --       end,
    --       desc = "Open Snipe buffer menu",
    --     },
    --   },
    --   config = function()
    --     local snipe = require("snipe")
    --
    --     -- Surcharge de la méthode de formatage des buffers
    --     local function custom_format(buffer)
    --       local max_path_width = 2
    --       local path = buffer.path or ""
    --       -- Troncature des chemins trop longs
    --       if #path > max_path_width then
    --         path = "…" .. path:sub(-max_path_width)
    --       end
    --       return string.format("[%d] %s", buffer.bufnr, path)
    --     end
    --
    --     -- Configuration de Snipe avec la fonction de formatage personnalisée
    --     snipe.setup({
    --       hints = {
    --         dictionary = "123456789",
    --       },
    --       navigate = {
    --         cancel_snipe = "<esc>",
    --         close_buffer = "d",
    --         under_cursor = "<Tab>",
    --       },
    --       sort = "default",
    --       buffer_formatter = custom_format, -- Utilisation de notre format personnalisé
    --     })
    --   end,
    -- },


    { "moll/vim-bbye" },

    { "mbbill/undotree" },

    { "hrsh7th/cmp-path" },

    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
        -- stylua: ignore
        keys = {
            { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
            { "<leader>qS", function() require("persistence").select() end,              desc = "Select Session" },
            { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
            { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't Save Current Session" },
        },
    },

    {
        -- You can also use the codeberg mirror if you want to use the plugin without relying on GitHub
        -- "https://codeberg.org/CodingThunder/zincoxide.git" -- for HTTPS
        -- "git@codeberg.org:CodingThunder/zincoxide.git"     -- for SSH
        -- NOTE: the username on both github and codeberg are different
        "thunder-coding/zincoxide",
        opts = {
            -- name of zoxide binary in your "$PATH" or path to the binary
            -- the command is executed using vim.fn.system()
            -- eg. "zoxide" or "/usr/bin/zoxide"
            zincoxide_cmd = "zoxide",
            -- Kinda experimental as of now
            complete = true,
            -- Available options { "tabs", "window", "global" }
            behaviour = "tabs",
        },
        cmd = { "Z", "Zg", "Zt", "Zw" },

        -- Notification du répertoire courant après un saut zoxide.
        -- Autocmd natif au lieu d'un patch du plugin : rien ne peut se périmer.
        -- Le motif suit `behaviour` ci-dessus : "tabs" utilise `tcd`, qui déclenche
        -- DirChanged avec le motif "tabpage". Si tu passes behaviour à "global" ou
        -- "window", remplace le motif par "global" ou "window".
        -- Ce ciblage évite aussi les doublons avec explorer_cd de snacks, qui fait
        -- un `cd` global et notifie déjà de son côté.
        init = function()
            vim.api.nvim_create_autocmd("DirChanged", {
                pattern = "tabpage",
                callback = function()
                    vim.notify("Current directory: " .. vim.fn.getcwd(),
                        vim.log.levels.INFO, { title = "Directory changed" })
                end,
            })
        end,
    },

    -- { 'akinsho/toggleterm.nvim', version = "*", config = true },

    {
        'jghauser/follow-md-links.nvim'
    },

    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                IMPORTANT = { icon = "󰋑 ", color = "error"  },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "default" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = "", color = "hint", alt = { "INFO" } },
                -- NOTE = { icon = "", color = "green_neon2", alt = { "INFO" } },
                -- NOTE = { icon = "", color = "test", alt = { "INFO" } },
                TEST = { icon = "󰙨", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
                SEP = { icon = "─", color = "info"},
                INSERT = { icon = "", color = "info"},
            },
            merge_keywords = false,
            gui_style = { fg = "NONE", bg = "BOLD" },
            highlight = {
                multiline = true,
                multiline_pattern = "^.",
                multiline_context = 10,
                before = "",
                keyword = "wide",
                after = "fg",
                pattern = [[.*<(KEYWORDS)\s*:]],
                comments_only = true, -- met true si tes TODO/FIX sont dans des commentaires
                max_line_len = 400,
                exclude = {},
            },
            colors = {
                -- error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                -- warning = { "DiagnosticWarn", "WarningMsg", "#e0af68" },
                info = { "DiagnosticInfo" },
                -- hint = { "DiagnosticHint", "#10b981" },
                -- default = { "Identifier", "#bb9af7" },
                -- test = { "Identifier", "#FF00FF" },

                error = "#ff4d4d",
                -- warning = "#fff176",
                warning = "#fff59d",  -- jaune clair légèrement néon
                -- info = "#6eeed9",
                -- info = "#64f2d8",
                -- info = "#5ef0d0" ,
                -- info = "#76ffe1",
                -- info = "#4df2d1" ,
                -- green_neon2 = "#4df2b3" ,
                -- green_neon2="#48e6aa",

                -- green_neon= "#66ff99",

                hint = "#10b981",
                default = "#bb9af7",
                test = "#ff8c42",
                -- test = "#f5b7ff"  -- rose pastel lumineux
                -- test = "#f28ce2"  -- rose-violet doux

            },
            search = {
                command = "rg",
                args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
                pattern = [[\b(KEYWORDS):]],
            },
        }
    },


    {
        "folke/snacks.nvim",
        priority = 1000,
        -- priority = 1000,
        lazy = false,
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
            bigfile = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            quickfile = { enabled = true },

            image = {
                enabled = false,

                formats = {
                },

                doc = {
                    enabled = false,
                }
            },
            lazygit = {
                enabled = true,
                configure = true,
            },


            picker = {
                enabled = true,
                matcher = {
                    sort_empty = true,
                    frecency = true,
                },

                notifications = {
                    wrap = true, -- Assure-toi que le wrapping est activé pour les notifications
                },
                -- debug = {
                --     scores = true, -- show scores in the list
                -- },

                sources = {


                    explorer = {

                        finder = "explorer",
                        sort = { fields = { "sort" } },
                        supports_live = true,
                        tree = true,
                        watch = true,
                        diagnostics = true,
                        diagnostics_open = false,
                        git_status = true,
                        git_status_open = false,
                        git_untracked = true,
                        follow_file = true,
                        focus = "list",
                        auto_close = false,
                        jump = { close = false },
                        layout = { preset = "sidebar", preview = false },
                        -- to show the explorer to the right, add the below to
                        -- your config under `opts.picker.sources.explorer`
                        -- layout = { layout = { position = "right" } },
                        formatters = {
                            file = { filename_only = true },
                            severity = { pos = "right" },
                        },
                        matcher = { sort_empty = false, fuzzy = false },
                        -- config = function(opts)
                        --     return require("snacks.picker.source.explorer").setup(opts)
                        -- end,
                        win = {
                            list = {
                                keys = {
                                    ["/"] = "toggle_focus", -- IMPORTANT
                                    ["<BS>"] = "explorer_up",
                                    ["<CR>"] = "confirm",
                                    ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                                    ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                                    ["l"] = "confirm",
                                    ["h"] = "explorer_close",                              -- close directory
                                    ["a"] = "explorer_add",
                                    ["d"] = "explorer_del",
                                    ["r"] = "explorer_rename",
                                    ["c"] = "explorer_copy",
                                    ["m"] = "explorer_move",
                                    ["o"] = "explorer_open", -- open with system application
                                    ["P"] = "toggle_preview",
                                    ["y"] = { "explorer_yank", mode = { "n", "x" } },
                                    ["p"] = "explorer_paste",
                                    ["u"] = "explorer_update",
                                    ["<c-c>"] = "tcd",
                                    ["<leader>/"] = "picker_grep",
                                    ["<c-t>"] = "terminal",
                                    ["."] = "explorer_focus",
                                    ["I"] = "toggle_ignored",
                                    ["H"] = "toggle_hidden",
                                    ["Z"] = "explorer_close_all",
                                    ["]g"] = "explorer_git_next",
                                    ["[g"] = "explorer_git_prev",
                                    ["]d"] = "explorer_diagnostic_next",
                                    ["[d"] = "explorer_diagnostic_prev",
                                    ["]w"] = "explorer_warn_next",
                                    ["[w"] = "explorer_warn_prev",
                                    ["]e"] = "explorer_error_next",
                                    ["[e"] = "explorer_error_prev",

                                    ["<Left>"] = "explorer_up",
                                    ["<Right>"] = "confirm",

                                    ["<C-left>"] = { "explorer_up_and_cd", mode = { "i", "n" } },
                                    ["<C-right>"] = { "explorer_cd", mode = { "i", "n" } },
                                },
                            },
                        },
                    },
                    -- Suivre les liens symboliques.
                    -- Les configs de ~/.config sont des liens vers le dépôt dotfiles ;
                    -- sans ceci, fd et rg les ignorent et la moitié des fichiers est
                    -- invisible (mesuré dans ~/.config/nvim : 289 fichiers sans, 575 avec).
                    files = {
                        follow = true,
                        hidden = true,
                    },

                    grep = {
                        follow = true,
                        hidden = true,
                    },
                },

                win = {
                    -- input window
                    input = {
                        keys = {
                            -- to close the picker on ESC instead of going to normal mode,
                            -- add the following keymap to your config
                            -- ["<Esc>"] = { "close", mode = { "n", "i" } },
                            ["/"] = "toggle_focus", -- IMPORTANT
                            -- ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
                            -- ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
                            ["<C-up>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-down>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-left>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-right>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-c>"] = { "cancel", mode = "i" },
                            ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
                            ["<CR>"] = { "confirm", mode = { "n", "i" } },
                            ["<Down>"] = { "list_down", mode = { "i", "n" } },
                            ["<Esc>"] = "cancel",
                            -- ["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
                            ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },-- IMPORTANT
                            ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },-- IMPORTANT

                            -- ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                            -- ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                            ["<Up>"] = { "list_up", mode = { "i", "n" } },
                            ["<a-d>"] = { "inspect", mode = { "n", "i" } },
                            ["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
                            ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } }, -- IMPORTANT
                            ["<c-h>"] = { "toggle_hidden", mode = { "i", "n" } }, -- IMPORTANT
                            ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
                            ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
                            ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
                            ["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
                            ["<c-a>"] = { "select_all", mode = { "n", "i" } },
                            ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
                            ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
                            ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
                            ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
                            ["<c-j>"] = { "list_down", mode = { "i", "n" } },
                            ["<c-k>"] = { "list_up", mode = { "i", "n" } },
                            ["<c-n>"] = { "list_down", mode = { "i", "n" } },
                            ["<c-p>"] = { "list_up", mode = { "i", "n" } },
                            ["<c-q>"] = { "qflist", mode = { "i", "n" } },
                            ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
                            ["<c-t>"] = { "tab", mode = { "n", "i" } },
                            ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
                            ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
                            ["<c-r>#"] = { "insert_alt", mode = "i" },
                            ["<c-r>%"] = { "insert_filename", mode = "i" },
                            ["<c-r><c-a>"] = { "insert_cWORD", mode = "i" },
                            ["<c-r><c-f>"] = { "insert_file", mode = "i" },
                            ["<c-r><c-l>"] = { "insert_line", mode = "i" },
                            ["<c-r><c-p>"] = { "insert_file_full", mode = "i" },
                            ["<c-r><c-w>"] = { "insert_cword", mode = "i" },
                            ["<c-w>H"] = "layout_left",
                            ["<c-w>J"] = "layout_bottom",
                            ["<c-w>K"] = "layout_top",
                            ["<c-w>L"] = "layout_right",
                            ["?"] = "toggle_help_input",
                            ["G"] = "list_bottom",
                            ["gg"] = "list_top",
                            ["j"] = "list_down",
                            ["k"] = "list_up",
                            ["q"] = "close",
                        },
                        b = {
                            minipairs_disable = true,
                        },
                    },
                    -- result list window
                    list = {
                        keys = {

                            ["<C-up>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-left>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },

                            ["<C-down>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-right>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["/"] = "toggle_focus", -- IMPORTANT
                            ["<2-LeftMouse>"] = "confirm",
                            ["<CR>"] = "confirm",   -- IMPORTANT
                            ["<Down>"] = "list_down",
                            ["<Esc>"] = "cancel",
                            ["<S-CR>"] = { { "pick_win", "jump" } },
                            -- ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },-- IMPORTANT
                            -- ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },-- IMPORTANT

                            ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                            ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                            ["<Up>"] = "list_up",
                            ["<a-d>"] = "inspect",
                            ["<a-f>"] = "toggle_follow",
                            ["<a-h>"] = "toggle_hidden", -- IMPORTANT
                            ["<c-h>"] = "toggle_hidden",
                            ["<a-i>"] = "toggle_ignored",
                            ["<a-m>"] = "toggle_maximize",
                            ["<a-p>"] = "toggle_preview",
                            ["<a-w>"] = "cycle_win",
                            ["<c-a>"] = "select_all",
                            ["<c-b>"] = "preview_scroll_up",
                            ["<c-d>"] = "list_scroll_down",
                            ["<c-f>"] = "preview_scroll_down",
                            ["<c-j>"] = "list_down",
                            ["<c-k>"] = "list_up",
                            ["<c-n>"] = "list_down",
                            ["<c-p>"] = "list_up",
                            ["<c-q>"] = "qflist",
                            ["<c-s>"] = "edit_split",
                            ["<c-t>"] = "tab",
                            ["<c-u>"] = "list_scroll_up",
                            ["<c-v>"] = "edit_vsplit",
                            ["<c-w>H"] = "layout_left",
                            ["<c-w>J"] = "layout_bottom",
                            ["<c-w>K"] = "layout_top",
                            ["<c-w>L"] = "layout_right",
                            ["?"] = "toggle_help_list",
                            ["G"] = "list_bottom",
                            ["gg"] = "list_top",
                            ["i"] = "focus_input",
                            ["j"] = "list_down",
                            ["k"] = "list_up",
                            ["q"] = "close",
                            ["zb"] = "list_scroll_bottom",
                            ["zt"] = "list_scroll_top",
                            ["zz"] = "list_scroll_center",
                        },
                        wo = {
                            conceallevel = 2,
                            concealcursor = "nvc",
                        },
                    },
                },
                -- Actions personnalisées.
                -- Déclarées ici plutôt qu'en patchant snacks : picker.opts.actions est
                -- consulté AVANT les actions internes du plugin (snacks/picker/core/actions.lua),
                -- donc une mise à jour de snacks ne peut pas les écraser.
                actions = {
                    explorer_cd = function(picker)
                        local path = picker:dir()
                        picker:set_cwd(path)
                        vim.cmd("cd " .. vim.fn.fnameescape(path))
                        vim.notify("Changed directory to: " .. path, vim.log.levels.INFO)
                        picker:find()
                    end,

                    explorer_up_and_cd = function(picker)
                        local path = vim.fs.dirname(picker:cwd())
                        picker:set_cwd(path)
                        vim.cmd("cd " .. vim.fn.fnameescape(path))
                        vim.notify("Changed directory to: " .. path, vim.log.levels.INFO)
                        picker:find()
                    end,

                    select = function(picker)
                        picker.list:select()
                    end,

                    -- Désélectionne tout
                    unselect_all = function(picker)
                        if picker.list and picker.list.set_selected then
                            picker.list:set_selected({})
                            picker.list:set_target()
                            if picker.find then
                                picker:find()
                            end
                        end
                    end,
                },
            },



            input = { enabled = true },
            win = {
                enabled = true,
                show = true,

                backdrop = false,
            },

            scroll = { enabled = false },
            words = { enabled = false },
            indent = { enabled = false },
            scope = { enabled = false },
            statuscolumn = { enabled = false },
            dim = { enabled = false },
            terminal = {
                enabled = false,
            },

            dashboard = {
                enabled = true,
                -- pane_gap = 8, -- empty columns between vertical panes
                pane_gap = 16, -- empty columns between vertical panes
                -- 51 et non 50 : le header ASCII fait 51 colonnes de large. Avec width = 50
                -- il débordait du panneau 1 et poussait le panneau 2 d'une colonne, mais
                -- uniquement sur ses propres lignes — l'art se retrouvait décalé en haut et
                -- pas en bas. Invisible du temps où l'art était une fenêtre flottante,
                -- positionnée indépendamment du contenu du panneau 1.
                width = 51,
                -- width = 60,
                -- row = nil,     -- dashboard position. nil for center
                -- col = nil,     -- dashboard position. nil for center
                preset = {
                    pick = nil,
                    keys = {
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "d", desc = "CodeDiff HEAD~1", action = ":CodeDiff HEAD~1" },
                        { icon = " ", key = "r", desc = "Refresh Git Diff HEAD~1", action = function() Snacks.dashboard.update() end },
                        -- { icon = " ", key = "f", desc = "Find File", action = function() Snacks.picker.files() end },
                        -- { icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
                        -- { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.picker.oldfiles() end },
                        -- { icon = " ", key = "c", desc = "Config", action = function() Snacks.picker.files({ cwd = "~/.config/nvim" }) end },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        -- { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                    -- Used by the `header` section
                    header = [[


 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░
         ░    ░  ░    ░ ░        ░   ░         ░
                                ░
                  ]],

                },
                -- formats = {
                --     key = function(item)
                --         return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
                --     end,
                -- },

                sections = {
                    { section = "header", gap = 2 },

                    { section = "keys", gap = 1, padding = 1 },
                    -- { pane = 1, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1, limit = 5 },

                    function()
                        -- Utiliser getcwd() plutôt que Snacks.git.get_root() qui n'est pas fiable au premier lancement
                        local cwd = vim.fn.getcwd()
                        local git_root_handle = io.popen("git -C " .. cwd .. " rev-parse --show-toplevel 2>/dev/null")
                        local git_root = git_root_handle:read("*a"):gsub("%s+$", "")
                        git_root_handle:close()

                        if git_root == "" then
                            return {
                                pane = 1,
                                icon = " ",
                                title = "Recent Files",
                                section = "recent_files",
                                indent = 2,
                                padding = 1,
                                limit = 7,
                            }
                        end

                        -- Vérifier qu'il y a au moins 2 commits
                        local check = io.popen("git -C " .. git_root .. " rev-parse --verify HEAD~1 2>/dev/null")
                        local result = check:read("*a")
                        check:close()

                        if result == "" then
                            return {
                                pane = 1,
                                icon = " ",
                                title = "No previous commit",
                                section = "terminal",
                                cmd = "echo 'Not enough commits yet. Need at least 2 commits to show diff.'",
                                height = 3,
                                padding = 1,
                            }
                        end

                        -- Compter les fichiers changés (sans la ligne summary)
                        local handle = io.popen("git -C " .. git_root .. " diff --stat HEAD~1 2>/dev/null | tail -n 1 | awk '{print $1}'")
                        local raw = handle:read("*a")
                        handle:close()
                        local file_count = tonumber((raw:gsub("%s+", ""))) or 0

                        local title = file_count == 1
                        and "Git Diff HEAD~1 (1 file)"
                        or ("Git Diff HEAD~1 (" .. file_count .. " files)")

                        -- local height = math.max(1, math.min(file_count+1, 7))
                        local height = 7
                        local visible = height - 1

                        -- Texte statique plutôt qu'une section "terminal".
                        -- L'ancienne version ajoutait « #os.time() » à la commande pour forcer
                        -- le rafraîchissement. Effet de bord : la clé de cache changeait à chaque
                        -- appel, donc git était relancé à CHAQUE dashboard:update() — donc à
                        -- chaque <leader>e — et son rendu asynchrone se voyait clignoter.
                        -- Ici git tourne une fois, en synchrone, quand la section est construite :
                        -- le texte est prêt avant l'affichage. La touche « r » rafraîchit toujours.
                        local out = vim.fn.system({
                            "git", "-C", git_root, "--no-pager", "diff", "--stat",
                            "--stat-width=50", "--color=always", "HEAD~1",
                        })
                        local dlines = vim.split(out, "\n", { plain = true })
                        while #dlines > 0 and dlines[#dlines] == "" do
                            table.remove(dlines)
                        end
                        if #dlines > visible then
                            dlines = vim.list_slice(dlines, 1, visible)
                        end

                        -- Deux éléments plutôt qu'un : dans D:format, dès que `text` est
                        -- défini, snacks ignore `icon` et `title` (le bloc `text` remplace
                        -- la colonne centrale). Le titre doit donc être son propre élément.
                        return {
                            { pane = 1, icon = " ", title = title },
                            {
                                pane = 1,
                                text = require("ansi_art").parse(table.concat(dlines, "\n")),
                                padding = 1,
                            },
                        }
                    end,


                    { section = "startup" },
                    -- ------------------------------------------------------------------
                    -- ART FIXE (PNG) — conservé, remplacé par le GIF animé ci-dessous.
                    -- Pour y revenir : décommenter ce bloc et commenter le suivant.
                    --
                    -- Texte coloré statique, plus une section "terminal".
                    --
                    -- POURQUOI : une section terminal est détruite et recréée à chaque
                    -- dashboard:update(), donc à chaque WinResized — donc à chaque
                    -- <leader>e. Elle vit dans une fenêtre flottante posée par-dessus le
                    -- dashboard, redimensionnée à chaque fois : d'où le clignotement et
                    -- l'art qui se déforme. Aucun réglage de largeur ne corrige ça, le
                    -- problème est la recréation elle-même.
                    --
                    -- lua/ansi_art.lua traduit les couleurs ANSI de chafa en morceaux de
                    -- texte avec groupes de surbrillance. Le résultat fait partie du
                    -- buffer du dashboard : jamais relancé, jamais reflowé, il suit la
                    -- mise en page sans bouger.
                    --
                    -- Pour régénérer l'art :
                    --   chafa --symbols all --size 50 image.png > samurai_logo_blue_doom_5040.txt
                    --
                    should_show_image() and {
                        {
                            text = require("ansi_art").read(
                                vim.fn.stdpath("config") .. "/samurai_logo_blue_doom_5040.txt"
                            ) or { { "" } },
                            pane = 2,
                        }
                    },
                    -- ------------------------------------------------------------------

                    -- ART ANIMÉ (GIF) — mêmes contraintes que le PNG ci-dessus : la
                    -- première image est du texte statique dans le buffer du dashboard
                    -- (c'est elle qui fixe la mise en page, jamais relancée ni reflowée),
                    -- les suivantes sont peintes par-dessus en extmarks. Toujours aucune
                    -- section "terminal", donc toujours aucun clignotement au <leader>e.
                    -- Le détail est dans lua/ansi_anim.lua.
                    --
                    -- Pour régénérer l'animation :
                    --   chafa --size 50 --font-ratio 10/24 samurai_float.gif > samurai_float_frames.txt
                    -- Le --font-ratio est obligatoire : redirigée dans un fichier, la
                    -- sortie de chafa ne peut plus mesurer le terminal et suppose des
                    -- cellules 1/2. Celles d'Alacritty en Roboto Mono 12.5 font 10 × 24 px,
                    -- d'où un dessin étiré de 20 % en hauteur si on ne le précise pas.
                    --
                    -- Le curseur du terminal est masqué tant que l'animation tourne, comme
                    -- le fait chafa lui-même : sinon il se fait peindre au milieu du dessin
                    -- et semble sauter au hasard. Pour le garder : hide_cursor = false.
                    --
                    -- OMBRES sur les contours (désactivées par défaut) — commun aux deux :
                    --   vim.g.ansi_art_shadow = true        -- fond du thème assombri de 35 %
                    --   vim.g.ansi_art_shadow = 0.5         -- plus marquées (0 à 1)
                    --   vim.g.ansi_art_shadow = "#14161b"   -- couleur imposée
                    -- À placer avant le chargement de lazy, ou à l'essai :
                    --   :lua vim.g.ansi_art_shadow = true; require("ansi_art").refresh()
                    -- puis rouvrir le dashboard (:lua Snacks.dashboard()).
                    -- should_show_image() and function()
                    --     local anim = require("ansi_anim").load(
                    --         vim.fn.stdpath("config") .. "/samurai_float_frames.txt",
                    --         { delay = 80 }   -- le GIF est cadencé à 8 cs par image
                    --     )
                    --     if not anim then
                    --         return {}
                    --     end
                    --     return {
                    --         pane = 2,
                    --         text = anim:text(),
                    --         render = function(dashboard, pos)
                    --             anim:attach(dashboard.buf, pos)
                    --         end,
                    --     }
                    -- end,
                },
            },
        },



        keys = {

            -- Picker (other)
            { "<leader>:",  function() Snacks.picker.command_history() end,              desc = "Command History" },
            { "<leader>fn", function() Snacks.picker.notifications({ wrap = true }) end, desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end,                       desc = "Dismiss All Notifications" },
            -- { "<leader>e",  function() Snacks.explorer() end,                            desc = "File Explorer" }, -- ~~~~~~~~~~~~~~~ <leader>E correspond à mini.files (explorer flottant) ~~~~~~~~~~~~~~~~~~

            -- Picker (file & lsp)
            { "<leader>ff", function() Snacks.picker.files() end,                        desc = "Picker Find Files" },
            { "<leader>fa", function() Snacks.picker.lsp_workspace_symbols() end,        desc = "LSP Workspace Symbols" },
            { "<leader>ga", function() Snacks.picker.lsp_workspace_symbols() end,        desc = "LSP Workspace Symbols" },
            { "<leader>gd", function() Snacks.picker.lsp_definitions() end,              desc = "Goto Definition" },
            { "<leader>fk", function() Snacks.picker.keymaps() end,                      desc = "Keymaps" },
            { "<leader>fp", function() Snacks.picker.projects() end,                     desc = "Projects" },

            -- Picker (Git)
            { "<leader>fb", function() Snacks.gitbrowse() end,                           desc = "Git Browse" },
            { "<leader>fc", function() Snacks.picker.git_log_file() end,                 desc = "Git Commit File" },
            { "<leader>fC", function() Snacks.picker.git_log() end,                      desc = "Git Commit Files" },
            -- { "<leader>fh", function() Snacks.picker.git_diff() end,                     desc = "Git Diff (Hunks)" },
            { "<leader>lg", function() Snacks.lazygit() end,                             desc = "Lazygit" },

            -- Picker (Diagnostics)
            { "<leader>ds", function() Snacks.picker.diagnostics() end,                  desc = "Diagnostics" },
            { "<leader>fd", function() Snacks.picker.diagnostics() end,                  desc = "Diagnostics" },


            -- { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },

            -- Terminal
            -- { "<c-ù>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
            -- {
            --     "<leader>N",
            --     desc = "Neovim News",
            --     function()
            --         Snacks.win({
            --             file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            --             width = 0.6,
            --             height = 0.6,
            --             wo = {
            --                 spell = false,
            --                 wrap = false,
            --                 -- signcolumn = "yes",
            --                 statuscolumn = " ",
            --                 conceallevel = 3,
            --             },
            --         })
            --     end,
            -- }
        },
        init = function()
            Snacks = require("snacks")


            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- important : permet de relancer le dashboard pour que git diff soit à jour notamment
                    if Snacks.dashboard then
                        Snacks.dashboard.update()
                    end

                    -- -- Aperçu d'image par chafa, au lieu du protocole graphique de snacks.
                    -- -- Surcharge du module depuis la config plutôt qu'un patch du plugin :
                    -- -- une mise à jour de snacks ne peut plus l'effacer.
                    -- -- NOTE: on passe { pty = true } SANS ft. La logique amont est
                    -- --       `pty = opts.pty ~= false and not opts.ft` : ajouter ft
                    -- --       désactiverait le terminal et chafa s'afficherait en échappements bruts.
                    -- local preview = require("snacks.picker.preview")
                    -- preview.image = function(ctx)
                    --     local path = Snacks.picker.util.path(ctx.item)
                    --     if not path then
                    --         ctx.preview:notify("no image path", "error")
                    --         return
                    --     end
                    --
                    --     local ext = path:match("^.+%.([^.]+)$")
                    --     local allowed = { png = true, jpg = true, jpeg = true, gif = true,
                    --                       bmp = true, webp = true, svg = true }
                    --     if not (ext and allowed[ext:lower()]) then
                    --         ctx.preview:notify("Unsupported image format", "warn")
                    --         return
                    --     end
                    --
                    --     ctx.preview:set_title(ctx.item.title or vim.fn.fnamemodify(path, ":t"))
                    --     local dim = ctx.preview.win:dim()
                    --     preview.cmd({
                    --         "chafa",
                    --         "--animate=off",
                    --         "--clear",
                    --         "--size", dim.width .. "x" .. dim.height,
                    --         path,
                    --     }, ctx, { pty = true })
                    -- end
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle.option("conceallevel",
                        { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map(
                        "<leader>ub")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                end,
            })

            -- update git diff si : on change de panel tmux et un nouveau fichier modifié est repéré et on est sur le buffer dashboard
            local last_git_diff = ""
            vim.api.nvim_create_autocmd("FocusGained", {
                pattern = "*",
                callback = function()
                    local buf = vim.api.nvim_get_current_buf()
                    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
                    if ft == "snacks_dashboard" and Snacks.dashboard then
                        local cwd = vim.fn.getcwd()
                        local handle = io.popen("git -C " .. cwd .. " diff --name-only HEAD 2>/dev/null")
                        local result = handle:read("*a")
                        handle:close()
                        if result ~= last_git_diff then
                            last_git_diff = result
                            Snacks.dashboard.update()
                        end
                    end
                end,
            })
        end,
    },


    { "tpope/vim-fugitive" },

    -- {
    --     'kristijanhusak/vim-dadbod-ui',
    --     dependencies = {
    --         { 'tpope/vim-dadbod', lazy = false },
    --         -- { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    --     },
    --     cmd = {
    --         'DBUI',
    --         'DBUIToggle',
    --         'DBUIAddConnection',
    --         'DBUIFindBuffer',
    --     },
    --     init = function()
    --         -- Your DBUI configuration
    --         vim.g.db_ui_use_nerd_fonts = 1
    --
    --         vim.g.db = 'postgresql://noah@localhost/db_test'
    --
    --             -- Mapping personnalisé pour exécuter dans le buffer courant
    --         vim.api.nvim_create_autocmd('FileType', {
    --             pattern = { 'sql', 'mysql', 'plsql' },
    --             callback = function()
    --                 vim.keymap.set('n', '<Leader>S', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
    --                 vim.keymap.set('v', '<Leader>S', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
    --             end,
    --         })
    --
    --         -- vim.g.dbs = {
    --         --     dev = 'postgresql://username:password@localhost:5432/dbname',
    --         --     -- Ajoutez d'autres connexions si nécessaire
    --         -- }
    --
    --         -- -- Charger les connexions depuis un fichier séparé
    --         -- local db_config = vim.fn.stdpath('config') .. '/db_connections.lua'
    --         -- if vim.fn.filereadable(db_config) == 1 then
    --         --     dofile(db_config)
    --         -- end
    --         -- vim.g.db_ui_save_location = vim.fn.stdpath('config') .. '/db_ui'
    --
    --         --[[
    --         Créez ~/.config/nvim/db_connections.lua :
    --         -- Ce fichier ne doit PAS être versionné (ajoutez-le au .gitignore)
    --         vim.g.db = 'postgresql://noah@localhost/db_test'
    --
    --         vim.g.dbs = {
    --             dev = 'postgresql://noah:password@localhost/db_test',
    --             prod = 'postgresql://noah:password@prod.example.com/production',
    --         }
    --
    --         ]]
    --
    --     end,
    -- },
    -- {
    --     'kristijanhusak/vim-dadbod-ui',
    --     dependencies = {
    --         { 'tpope/vim-dadbod', lazy = false },
    --     },
    --     cmd = {
    --         'DBUI',
    --         'DBUIToggle',
    --         'DBUIAddConnection',
    --         'DBUIFindBuffer',
    --     },
    --     init = function()
    --         vim.g.db_ui_use_nerd_fonts = 1
    --         -- vim.g.db = 'postgresql://noah@localhost/db_test'
    --         vim.g.db_ui_win_position = 'left'
    --         vim.g.db_ui_winwidth = 30
    --         vim.g.dbs = {
    --             { name = 'projet_local', url = 'postgresql://noah@localhost/db_test' },
    --             { name = 'tp_select_local', url = 'postgresql://noah@localhost/db_tp_select' },
    --         }
    --         -- vim.g.db_ui_show_notifications = 0
    --     end,
    --     config = function()
    --         local function close_dbout_window()
    --             local wins = vim.api.nvim_list_wins()
    --             for _, win in ipairs(wins) do
    --                 local buf = vim.api.nvim_win_get_buf(win)
    --                 local filetype = vim.bo[buf].filetype
    --                 if filetype == 'dbout' then
    --                     vim.api.nvim_win_close(win, false)
    --                     return true
    --                 end
    --             end
    --             return false
    --         end
    --
    --
    --         local function save_dbout_to_buffer()
    --             -- Chercher la fenêtre dbout
    --             local dbout_win = nil
    --             local wins = vim.api.nvim_list_wins()
    --
    --             for _, win in ipairs(wins) do
    --                 local buf = vim.api.nvim_win_get_buf(win)
    --                 local filetype = vim.bo[buf].filetype
    --                 if filetype == 'dbout' then
    --                     dbout_win = win
    --                     break
    --                 end
    --             end
    --
    --             if not dbout_win then
    --                 vim.notify('No dbout window found', vim.log.levels.INFO)
    --                 return
    --             end
    --
    --             -- Sauvegarder la fenêtre actuelle
    --             local original_win = vim.api.nvim_get_current_win()
    --
    --             -- Aller à la fenêtre dbout
    --             vim.api.nvim_set_current_win(dbout_win)
    --
    --             -- Créer le fichier temporaire
    --             local filename = "/tmp/dbout_" .. os.date('%H%M%S') .. ".txt"
    --             vim.cmd("w " .. filename)
    --
    --             -- Fermer la fenêtre dbout
    --             vim.api.nvim_win_close(dbout_win, false)
    --
    --             -- Revenir à la fenêtre originale et ouvrir le fichier
    --             vim.api.nvim_set_current_win(original_win)
    --             vim.cmd("edit " .. filename)
    --             vim.bo.buflisted = true
    --
    --             -- vim.notify('DBout saved to: ' .. filename, vim.log.levels.INFO)
    --             vim.cmd("only")
    --         end
    --
    --         -- Remplacer le mapping <leader>S original
    --         vim.keymap.set('n', '<leader>L', function()
    --             -- Exécuter la requête SQL (commande originale de dbui)
    --             vim.cmd('DB')
    --
    --             -- Attendre un peu que le résultat soit affiché puis sauvegarder
    --             vim.defer_fn(function()
    --                 save_dbout_to_buffer()
    --             end, 2000)
    --         end, { desc = 'Execute query and save to buffer' })
    --
    --
    --
    --         vim.keymap.set('n', '<leader>R', function()
    --             if not close_dbout_window() then
    --                 vim.notify('No dbout window found', vim.log.levels.INFO)
    --             end
    --         end, { desc = 'Close dbout result window' })
    --
    --         vim.keymap.set('n', '<leader>dc', function()
    --             if not close_dbout_window() then
    --                 vim.notify('No dbout window found', vim.log.levels.INFO)
    --             end
    --         end, { desc = 'Close dbout result window' })
    --
    --         vim.keymap.set('n', '<leader>b', save_dbout_to_buffer, { desc = 'Save dbout to buffer' })
    --
    --     end,
    --     keys = {
    --         { '<leader>db', '<cmd>DBUIToggle<cr>', desc = 'Toggle DBUI' },
    --         { '<leader>df', '<cmd>DBUIFindBuffer<cr>', desc = 'DBUI Find Buffer' },
    --     },
    -- },



    -- Lua
    { "shortcuts/no-neck-pain.nvim" },

    -- Lua
    {
        "folke/zen-mode.nvim",
        opts = {
            window = {
                backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
                -- height and width can be:
                -- * an absolute number of cells when > 1
                -- * a percentage of the width / height of the editor when <= 1
                -- * a function that returns the width or the height
                width = 120, -- width of the Zen window
                height = 1,  -- height of the Zen window
                -- by default, no options are changed for the Zen window
                -- uncomment any of the options below, or add other vim.wo options you want to apply
                options = {
                    -- signcolumn = "no", -- disable signcolumn
                    -- number = false, -- disable number column
                    -- relativenumber = false, -- disable relative numbers
                    -- cursorline = false, -- disable cursorline
                    -- cursorcolumn = false, -- disable cursor column
                    -- foldcolumn = "0", -- disable fold column
                    -- list = false, -- disable whitespace characters
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false,   -- disables the ruler text in the cmd line area
                    showcmd = false, -- disables the command in the last line of the screen
                    -- you may turn on/off statusline in zen mode by setting 'laststatus'
                    -- statusline will be shown only if 'laststatus' == 3
                    laststatus = 3,
                },
                -- twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
                gitsigns = { enabled = true },
                -- tmux = { enabled = false },
                -- todo = { enabled = false },
                alacritty = {
                    enabled = false,
                    font = "14",
                },
            },
            -- callback where you can add custom code when the Zen window opens
            on_open = function(win)
            end,
            -- callback where you can add custom code when the Zen window closes
            on_close = function()
            end,
        }
    },

    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },
    {
        "xzbdmw/colorful-menu.nvim",
        config = function()
            -- You don't need to set these options.
            require("colorful-menu").setup({
                ls = {
                    lua_ls = {
                        -- Maybe you want to dim arguments a bit.
                        arguments_hl = "@comment",
                    },
                    gopls = {
                        -- By default, we render variable/function's type in the right most side,
                        -- to make them not to crowd together with the original label.

                        -- when true:
                        -- foo             *Foo
                        -- ast         "go/ast"

                        -- when false:
                        -- foo *Foo
                        -- ast "go/ast"
                        align_type_to_right = true,
                        -- When true, label for field and variable will format like "foo: Foo"
                        -- instead of go's original syntax "foo Foo". If align_type_to_right is
                        -- true, this option has no effect.
                        add_colon_before_type = false,
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    -- for lsp_config or typescript-tools
                    ts_ls = {
                        -- false means do not include any extra info,
                        -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
                        extra_info_hl = "@comment",
                    },
                    vtsls = {
                        -- false means do not include any extra info,
                        -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
                        extra_info_hl = "@comment",
                    },
                    ["rust-analyzer"] = {
                        -- Such as (as Iterator), (use std::io).
                        extra_info_hl = "@comment",
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    clangd = {
                        -- Such as "From <stdio.h>".
                        extra_info_hl = "@comment",
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                        -- the hl group of leading dot of "•std::filesystem::permissions(..)"
                        import_dot_hl = "@comment",
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    zls = {
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                    },
                    roslyn = {
                        extra_info_hl = "@comment",
                    },
                    dartls = {
                        extra_info_hl = "@comment",
                    },
                    -- The same applies to pyright/pylance
                    basedpyright = {
                        -- It is usually import path such as "os"
                        extra_info_hl = "@comment",
                    },
                    -- If true, try to highlight "not supported" languages.
                    fallback = true,
                    -- this will be applied to label description for unsupport languages
                    fallback_extra_info_hl = "@comment",
                },
                -- If the built-in logic fails to find a suitable highlight group for a label,
                -- this highlight is applied to the label.
                fallback_highlight = "@variable",
                -- If provided, the plugin truncates the final displayed text to
                -- this width (measured in display cells). Any highlights that extend
                -- beyond the truncation point are ignored. When set to a float
                -- between 0 and 1, it'll be treated as percentage of the width of
                -- the window: math.floor(max_width * vim.api.nvim_win_get_width(0))
                -- Default 60.
                max_width = 60,
            })
        end,
    },

    {
        "monkoose/matchparen.nvim",
        event = "VeryLazy",
        config = function()
            require('matchparen').setup({
                enabled = true,
                hl_group = 'MatchParen',
                debounce_time = 0,
            })
        end,
    },


    {
            "saghen/blink.cmp",
            -- build = 'cargo build --release',
            enabled = true, --------------------------------------------------------------------------------------------------------------------------------
            dependencies = {

                "hrsh7th/nvim-cmp",

                {
                    "windwp/nvim-autopairs",
                    opts = {
                        fast_wrap = {},
                        disable_filetype = { "TelescopePrompt", "vim" },
                    },
                    config = function(_, opts)
                        require("nvim-autopairs").setup(opts)

                        -- setup cmp for autopairs
                        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
                        require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done)
                    end,
                },
                { 'L3MON4D3/LuaSnip',            version = 'v2.*' }, -- utiliser uniquement pour fichier .tex
                { "rafamadriz/friendly-snippets" },
            },

            opts = function(_, opts)

                opts.enabled = function()
                    local filetype = vim.bo[0].filetype
                    if filetype == "TelescopePrompt" or filetype == "minifiles" or filetype == "snacks_picker_input" then
                        return false
                    end
                    return true
                end

                opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
                    default = { "lsp", "path", "snippets", "buffer", "cmdline" },
                    -- per_filetype = {
                    --     sql = { 'dadbod', 'buffer', 'path' }, -- dadbod en premier pour la priorité
                    -- },
                    providers = {
                        lsp = {
                            name = "lsp",
                            enabled = true,
                            module = "blink.cmp.sources.lsp",
                            -- min_keyword_length = 1,
                            score_offset = 90, -- the higher the number, the higher the priority
                        },
                        path = {
                            name = "Path",
                            module = "blink.cmp.sources.path",
                            score_offset = 35,
                            fallbacks = { "buffer" },
                            -- min_keyword_length = 1,
                            opts = {
                                trailing_slash = true,
                                label_trailing_slash = true,
                                get_cwd = function(context)
                                    return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                                end,
                                show_hidden_files_by_default = true,
                            },

                        },
                        buffer = {
                            name = "Buffer",
                            enabled = true,
                            max_items = 7,
                            module = "blink.cmp.sources.buffer",
                            -- score_offset = 16, -- the higher the number, the higher the priority
                            score_offset = 20,
                        },

                        -- dadbod = {
                        --     name = "Dadbod",
                        --     module = "vim_dadbod_completion.blink",
                        --     score_offset = 50, -- the higher the number, the higher the priority
                        --     max_items = 10,
                        -- },

                        snippets = {
                            name = "snippets",
                            score_offset = 25, -- the higher the number, the higher the priority
                            max_items = 4,
                            enabled = function()
                                local ft = vim.bo.filetype
                                return ft == "tex" -- or ft == "rust"
                            end,
                        },

                        cmdline = {
                            -- min_keyword_length = 1,
                            score_offset = 999, -- the higher the number, the higher the priority
                        }

                    },
                })


                -- Experimental signature help support

                opts.signature = {
                    enabled = true,
                    trigger = {
                        -- Show the signature help automatically
                        enabled = true,
                        -- Show the signature help window after typing any of alphanumerics, `-` or `_`
                        show_on_keyword = true,
                        blocked_trigger_characters = {},
                        blocked_retrigger_characters = {},
                        -- Show the signature help window after typing a trigger character
                        show_on_trigger_character = true,
                        -- Show the signature help window when entering insert mode
                        show_on_insert = true,
                        -- Show the signature help window when the cursor comes after a trigger character when entering insert mode
                        show_on_insert_on_trigger_character = true,
                    },
                    window = {
                        min_width = 1,
                        max_width = 100,
                        max_height = 10,
                        border = 'single',
                        winblend = 0,
                        winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
                        scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
                        -- Which directions to show the window,
                        -- falling back to the next direction when there's not enough space,
                        -- or another window is in the way
                        -- direction_priority = { 's', 'e' },
                        direction_priority = { 's' },
                        -- Disable if you run into performance issues
                        treesitter_highlighting = true,
                        show_documentation = false,
                    },
                }

                opts.cmdline = {
                    enabled = true,

                    keymap = {
                        -- preset = 'inherit',
                        -- ['<Esc>'] = { 'hide' }, -- marche mais je peux plus quitter la cmdline ...
                        ["<Tab>"] = { "select_and_accept" },  -- Tab accepte la première suggestion
                        ["<S-Tab>"] = { "select_prev", "fallback" },
                        ['<Down>'] = { 'select_next', 'fallback' },
                        ['<Up>'] = { 'select_prev', 'fallback' },

                    },
                    completion = {
                        trigger = {
                            -- Ne pas bloquer le caractère "/" comme déclencheur

                            show_on_blocked_trigger_characters = {},
                            show_on_x_blocked_trigger_characters = {},
                        },
                        menu = { 
                            auto_show = function(ctx, _) 
                                if ctx.mode == 'cmdwin' then
                                    return true
                                end
                                if ctx.mode == 'cmdline' then
                                    local cmdline = vim.fn.getcmdline()

                                    -- Ne pas afficher pour les commandes simples de base
                                    local simple_cmds = { "^q!?$", "^w!?$", "^wq!?$", "^x!?$", "^qa!?$", "^wqa!?$" }
                                    for _, pattern in ipairs(simple_cmds) do
                                        if cmdline:match(pattern) then
                                            return false
                                        end
                                    end

                                    -- Afficher dès qu'on commence à taper
                                    return #cmdline > 0
                                end
                                return false
                            end 
                        },
                        -- menu = {
                        --     auto_show = true
                        -- },
                        list = {
                            selection = {
                                preselect = true,
                                auto_insert = false,  -- Attendre Tab pour accepter
                            },
                        },
                        ghost_text = { enabled = false },
                    }
                }


                opts.completion = {

                    trigger = {
                        show_on_trigger_character = true,
                    },

                    accept = {
                        auto_brackets = {
                            enabled = true,
                            default_brackets = { '(', ')' },
                            -- Overrides the default blocked filetypes
                            override_brackets_for_filetypes = {},
                            kind_resolution = {
                                enabled = true,
                                blocked_filetypes = { 'typescriptreact', 'javascriptreact', 'vue', 'typescript', 'javascript' },
                            },
                            -- Asynchronously use semantic token to determine if brackets should be added
                            semantic_token_resolution = {
                                enabled = true,
                                blocked_filetypes = { 'java' },
                                timeout_ms = 400,
                            },
                        },

                    },

                    keyword = {
                        -- 'prefix' will fuzzy match on the text before the cursor
                        -- 'full' will fuzzy match on the text before *and* after the cursor
                        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
                        range = "full",
                    },
                    menu = {
                        border = "single",

                        -- vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", {
                        --     fg = "#ffffff",  -- Couleur du texte (premier plan)
                        --     bg = "#ff0000",  -- Couleur de fond
                        --     bold = true,     -- Appliquer un texte en gras
                        -- }),

                        winhighlight =
                        'Normal:BlinkCmpLabel,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None',

                        draw = {
                            treesitter = { "lsp" },
                            columns = { { "kind_icon" }, { "label", gap = 1 } },
                            -- components = {
                            --     label = {
                            --         text = function(ctx)
                            --             return require("colorful-menu").blink_components_text(ctx)
                            --         end,
                            --         highlight = function(ctx)
                            --             return require("colorful-menu").blink_components_highlight(ctx)
                            --         end,
                            --     },
                            -- },

                            components = {
                                label = {
                                    text = function(ctx)
                                        return require("colorful-menu").blink_components_text(ctx)
                                    end,
                                    highlight = function(ctx)
                                        -- Récupération des highlights de colorful-menu
                                        local highlights = require("colorful-menu").blink_components_highlight(ctx) or {}

                                        -- Ajout du surlignage pour les caractères correspondants au fuzzy matching (à la fin)

                                        -- vim.api.nvim_set_hl(0, "MyErrorMsg", { fg = "#f38ba8", bold = true })
                                        -- vim.api.nvim_set_hl(0, "MyInfoMsg", { fg = "#94e2d5", bold = true })
                                        --
                                        -- for _, idx in ipairs(ctx.label_matched_indices or {}) do
                                        --     table.insert(highlights, { idx, idx + 1, group = 'MyErrorMsg' }) -- Vérifier si ça force le changement
                                        -- end


                                        return highlights
                                    end,
                                },
                            },



                        },
                    },


                    -- Définition du groupe de surlignage pour les lettres correspondant au fuzzy matcher
                    vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch",
                        { fg = "#ffffff", bg = "#ffff00", bold = true, underline = true }),

                    list = {
                        selection = {
                            preselect = true,
                            auto_insert = true,
                        },


                    },


                    documentation = {
                        auto_show = false,
                        window = {
                            border = "single",
                            winhighlight = 'Normal:NormalFloat,FloatBorder:WarningMsg',
                        },
                    },
                    -- Displays a preview of the selected item on the current line
                    ghost_text = {
                        enabled = false,
                    },
                }

                -- Priorité par type d'item : les fonctions/méthodes remontent,
                -- les constantes / variables / modules descendent (ex: `np.` en Python)
                local kind_priority = nil
                local function kind_rank(item)
                    if kind_priority == nil then
                        local K = require("blink.cmp.types").CompletionItemKind
                        kind_priority = {
                            -- 1 : tout ce qui s'utilise directement. Variable est ici volontairement :
                            -- les ufuncs numpy (np.abs, np.cos, np.arccos...) sont des instances de
                            -- np.ufunc, donc pyright les renvoie en Variable et non en Function.
                            [K.Method]        = 1,
                            [K.Function]      = 1,
                            [K.Variable]      = 1,
                            [K.Field]         = 1,
                            [K.Property]      = 1,
                            [K.Constructor]   = 1,
                            -- 2 : les types
                            [K.Class]         = 2,
                            [K.Struct]        = 2,
                            [K.Interface]     = 2,
                            [K.Enum]          = 2,
                            [K.TypeParameter] = 2,
                            -- 3 : les sous-modules (np.linalg, np.random)
                            [K.Module]        = 3,
                            -- 4 : les constantes (np.pi, np.inf, np.ALLOW_THREADS, np.MAXDIMS)
                            [K.Value]         = 4,
                            [K.Constant]      = 4,
                            [K.EnumMember]    = 4,
                            [K.Keyword]       = 5,
                            [K.Snippet]       = 6,
                            [K.Text]          = 7,
                        }
                    end
                    return kind_priority[item.kind] or 3
                end

                opts.fuzzy = {
                    implementation = "prefer_rust_with_warning",

                    -- ordre de tri : match exact > score du fuzzy > type d'item > sortText du LSP > label
                    sorts = {
                        "exact",
                        "score",
                        function(a, b)
                            local ra, rb = kind_rank(a), kind_rank(b)
                            if ra ~= rb then return ra < rb end
                        end,
                        -- sort_text insensible a la casse : sinon 'S' (0x53) passe avant 'a' (0x61)
                        -- et np.ScalarType se retrouve devant np.abs. Les prefixes de priorite
                        -- du serveur (pyright : 09. normal, 10. , 11. dunders) restent intacts.
                        function(a, b)
                            local sa, sb = a.sortText, b.sortText
                            if sa == nil or sb == nil then return end
                            sa, sb = sa:lower(), sb:lower()
                            if sa ~= sb then return sa < sb end
                        end,
                        "label",
                    },

                    prebuilt_binaries = {
                        download = true,
                        ignore_version_mismatch = false,
                        force_version = nil,
                        force_system_triple = nil,
                        extra_curl_args = {}
                    },
                }

                opts.keymap = {
                    preset = "none",
                    ["<Tab>"] = { 
                        function(cmp)
                            if cmp.snippet_active() then
                                return cmp.snippet_forward()
                            else
                                return cmp.select_and_accept()
                            end
                        end,
                        "fallback" 
                    },
                    ["<S-Tab>"] = { "snippet_backward", "fallback" },
                    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                    ['<Up>'] = { 'select_prev', 'fallback' },
                    ['<Down>'] = { 'select_next', 'fallback' },
                    ['<C-w>'] = { 'select_prev', 'fallback_to_mappings' },
                    ['<C-x>'] = { 'select_next', 'fallback_to_mappings' },
                    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
                    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
                }


                return opts
            end,
        },


        {"nanotee/sqls.nvim"},

        -- REFONTE DE MA CONFIG LSP

        {
            'neovim/nvim-lspconfig',

            -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ permet quand je fais nvim fichier.c de ne pas avoir les arguments d'une fonction automatiquement écrits quand je fais tab entre les parenthèses
            lazy = false,

            dependencies = {
                'saghen/blink.cmp',
                'williamboman/mason.nvim',
                'williamboman/mason-lspconfig.nvim',
                'ray-x/lsp_signature.nvim',
            },

            opts = {
                servers = {
                    lua_ls = {
                        settings = {
                            Lua = {
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                            },
                        },
                    },

                    clangd = {
                        cmd = { "clangd",
                        "--background-index",
                        "-j",
                        "4",
                        "--malloc-trim",
                        "--pch-storage=memory",
                        },
                        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                        root_dir = vim.fs.dirname(vim.fs.find({
                            'compile_commands.json', '.clangd', '.git'
                        }, { upward = true })[1]),
                        -- NOTE: C'est ici que tu peux désactiver le grisé sémantique globalement
                        -- on_init = function(client)
                        --     client.server_capabilities.semanticTokensProvider = nil
                        -- end,
                    },

                    texlab = {
                        filetypes = { "tex", "bib" },
                    },

                    ts_ls = {

                    },

                    jdtls = {
                        filetypes = { "java" },
                        root_dir = vim.fs.dirname(vim.fs.find({
                            'pom.xml', 'build.gradle', '.git'
                        }, { upward = true })[1]),
                        settings = {
                            java = {
                                signatureHelp = { enabled = true };

                            }
                        }
                    },

                    pyright = {},

                    rust_analyzer = {
                        settings = {
                            ["rust-analyzer"] = {
                                diagnostics = {
                                    enable = true,
                                    enableExperimental = true,
                                },
                                checkOnSave = false,
                                check = {
                                    command = "check",
                                    -- command = "clippy",
                                    allTargets = true,
                                },
                                cargo = {
                                    allFeatures = true,
                                    loadOutDirsFromCheck = true,
                                },
                                procMacro = {
                                    enable = true,
                                },
                                completion = {
                                    callable = {
                                        snippets = "add_parentheses",
                                    },
                                },
                            },
                        },
                    },

                    sqls = (function()

                        -- ============================================================================================================================
                        -- TOUJOURS mettre un fichier config.yml au root du projet (cf template ~/.config/sqls/config.yml), ex sans mdp:
                        --[[ 
                        connections:
                          - alias: db_test
                            driver: postgresql
                            proto: tcp
                            host: localhost
                            port: 5432
                            user: noah
                            dbName: db_test
                            params:
                              sslmode: disable
                        ]]

                        -- ============================================================================================================================

                        local config_path = "config.yml"

                        -- Vérifie que le fichier existe
                        if vim.fn.filereadable(config_path) == 0 then
                            -- vim.notify("Fichier SQLs config non trouvé : " .. config_path .. ", le LSP utilisera la config globale", vim.log.levels.WARN)
                            config_path = nil -- laisse sqls utiliser la config par défaut
                        end

                        return {
                            cmd = (config_path ~= nil) and { "sqls", "--config", config_path } or { "sqls" },
                            filetypes = { "sql" },
                            single_file_support = true,
                            -- root_dir = project_root,
                        }
                    end)()

                },

            },

            config = function(_, opts)
                local signature = require('lsp_signature')
                local capabilities_base = require('blink.cmp').get_lsp_capabilities()

                --  Fonction utilitaire : capabilities dynamiques selon le type de fichier
                local function get_capabilities_for_server(server_name)
                    -- local enable_snippets = (server_name == "texlab" or server_name=="rust_analyzer")
                    local enable_snippets = (server_name == "texlab")
                    return require('blink.cmp').get_lsp_capabilities({
                        textDocument = {
                            completion = { completionItem = { snippetSupport = enable_snippets } },
                        },
                    })
                end

                -- on_attach commun
                local function on_attach(client, bufnr)
                    local opts = { noremap = true, silent = true, buffer = bufnr }

                    vim.keymap.set('n', '<leader>gh', vim.lsp.buf.hover, opts)
                    -- vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, opts) -- cf partie snacks
                    vim.keymap.set('n', '<leader>gr', '<cmd>Telescope lsp_references<cr>', opts)
                    vim.keymap.set('n', '<leader>gl', '<cmd>Trouble lsp toggle focus=true<cr>', opts)

                    signature.on_attach({
                        bind = true,
                        handler_opts = { border = "rounded" },
                        floating_window = false,
                        hint_enable = false,
                    }, bufnr)

                end

                -- Bordures pour les diagnostics
                local hover = vim.lsp.buf.hover
                vim.lsp.buf.hover = function()
                    hover({border = 'rounded',})
                end

                -- Bordures pour les diagnostics
                vim.diagnostic.config({
                    -- NOTE: SI j'ai envie de mettre les popups diagnostics à côtés des erreurs sans que je fasse <leader>dd
                    -- virtual_text = {
                    --     spacing = 4,
                    --     prefix = "󰝤" -- ou "▪", "■", "",
                    -- },

                    float = { border = "rounded" }
                })

                -- Setup Mason
                require('mason').setup()
                require('mason-lspconfig').setup({
                    ensure_installed = vim.tbl_keys(opts.servers),
                    automatic_installation = true,
                })


                -- Configurer chaque serveur via la nouvelle API
                for name, config in pairs(opts.servers) do
                    vim.lsp.config[name] = vim.tbl_deep_extend("force", config, {
                        on_attach = on_attach,
                        capabilities = get_capabilities_for_server(name),
                    })
                end

            end,
        }
})

