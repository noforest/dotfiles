-- lua/clangd_auto.lua
--
-- Ce module génère automatiquement un fichier .clangd à la racine du projet
-- en scannant les macros préprocesseur C dans les fichiers sources.
--
-- LOGIQUE PRINCIPALE :
--
-- 1. scan_ifdef_macros() : parcourt tous les .c/.h/.cc et collecte :
--    - ifdef_macros  : macros vues dans #ifdef ET #if defined()
--                      → même sémantique, même traitement
--    - ifndef_macros : macros vues dans #ifndef → NE seront PAS définies
--
--    Les macros présentes dans ifndef_macros sont retirées de ifdef_macros.
--
-- 2. scan_defines() : collecte les #define NOM valeur
--    Utilisé UNIQUEMENT pour résoudre les valeurs des groupes #if X==Y.
--    Ces valeurs ne sont PAS écrites dans le .clangd car elles sont
--    déjà présentes dans les fichiers sources, clangd les lit naturellement.
--
-- 3. scan_conditions() : collecte les groupes mutuellement exclusifs
--    Exemple :
--      #if SCHED_POLICY == SCHED_FIFO       → groups["SCHED_POLICY"][1]
--      #elif SCHED_POLICY == SCHED_PRIORITY → groups["SCHED_POLICY"][2]
--    → demande à l'utilisateur quelle branche activer
--
-- CE QUI EST ECRIT dans le .clangd final :
--   - #ifdef / #if defined() → question posée : tout, rien, ou un par un
--   - #ifndef                → NON définies
--   - #if X==Y               → valeur choisie + valeur de la constante choisie
--   - #define déjà dans les sources → NON écrits (clangd les lit naturellement)
--   - Guards d'include (__NOM__) → ignorés (commence par _)
--   - Constantes numériques (R0, OP_ADD...) → ignorées

local M = {}

local IGNORE = {
    ["__linux__"]       = true, ["__APPLE__"]    = true, ["__WIN32__"]      = true,
    ["__cplusplus"]     = true, ["__GNUC__"]     = true, ["_WIN32"]         = true,
    ["__x86_64__"]      = true, ["NDEBUG"]       = true, ["NULL"]           = true,
    ["EXIT_SUCCESS"]    = true, ["EXIT_FAILURE"] = true, ["EINVAL"]         = true,
    ["EDEADLK"]         = true, ["ESRCH"]        = true, ["__STDC__"]       = true,
    ["__STRICT_ANSI__"] = true,
}

local SKIP_DIRS = { "/%.git/", "/build/", "/build_pthread/", "/test/" }

local function should_skip_file(file)
    for _, pat in ipairs(SKIP_DIRS) do
        if file:match(pat) then return true end
    end
    return false
end

local function is_feature_flag(name, value)
    if IGNORE[name]  then return false end
    if #name <= 2    then return false end

    if name:match("^[RS]%d+$")                        then return false end
    if name:match("^[A-Z][A-Z]?%d*$") and #name <= 4 then return false end
    if name:match("^I_")                              then return false end
    if name:match("^OP_")                             then return false end
    if name:match("FMT$")                             then return false end
    if name:match("^BCOND$")                          then return false end
    if name:match("^SPECIAL$")                        then return false end
    if name:match("^OMAGIC$")                         then return false end
    if name:match("_H$")                              then return false end

    if type(value) == "number" and value > 10 then return false end

    return true
end

local function restart_clangd()
    for _, client in ipairs(vim.lsp.get_clients()) do
        if client.name == "clangd" then
            vim.cmd("LspRestart clangd")
            return
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Scan #ifdef / #if defined() / #ifndef
-- ifdef_macros  : #ifdef ET #if defined() → même sémantique
-- ifndef_macros : #ifndef → ne pas définir
-- ─────────────────────────────────────────────────────────────────────────────
local function scan_ifdef_macros(root)
    local ifdef_macros  = {}
    local ifndef_macros = {}

    local files = vim.fn.globpath(root, "**/*.c",  false, true)
    vim.list_extend(files, vim.fn.globpath(root, "**/*.h",  false, true))
    vim.list_extend(files, vim.fn.globpath(root, "**/*.cc", false, true))

    for _, file in ipairs(files) do
        if not should_skip_file(file) then
            for _, line in ipairs(vim.fn.readfile(file)) do

                local m1 = line:match("^%s*#ifdef%s+([%u][%u%d_]+)")
                if m1 and not IGNORE[m1] and is_feature_flag(m1, 1) then
                    ifdef_macros[m1] = true
                end

                local m2 = line:match("^%s*#ifndef%s+([%u][%u%d_]+)")
                if m2 and not IGNORE[m2] and is_feature_flag(m2, 1) then
                    ifndef_macros[m2] = true
                end

                for m3 in line:gmatch("defined[%s%(]+([%u][%u%d_]+)") do
                    if not IGNORE[m3] and is_feature_flag(m3, 1) then
                        ifdef_macros[m3] = true
                    end
                end
            end
        end
    end

    return ifdef_macros, ifndef_macros
end

-- ─────────────────────────────────────────────────────────────────────────────
-- #define NOM valeur + résolution des alias
-- Pas de filtre sur la valeur : utilisé uniquement pour résoudre
-- les groupes #if X==Y, pas pour écrire dans le .clangd
-- ─────────────────────────────────────────────────────────────────────────────
local function scan_defines(root)
    local raw = {}
    local files = vim.fn.globpath(root, "**/*.c",  false, true)
    vim.list_extend(files, vim.fn.globpath(root, "**/*.h",  false, true))
    vim.list_extend(files, vim.fn.globpath(root, "**/*.cc", false, true))

    for _, file in ipairs(files) do
        if not should_skip_file(file) then
            for _, line in ipairs(vim.fn.readfile(file)) do

                local name, val = line:match(
                    "^%s*#define%s+([%u][%u%d_]+)%s+(%d+)%s*$")
                if name and not IGNORE[name] and #name > 2 then
                    raw[name] = tonumber(val)
                end

                local aname, aval = line:match(
                    "^%s*#define%s+([%u][%u%d_]+)%s+([%u][%u%d_]+)%s*$")
                if aname and aval
                    and not IGNORE[aname] and not IGNORE[aval] then
                    raw[aname] = aval
                end
            end
        end
    end

    for name, val in pairs(raw) do
        if type(val) == "string" and raw[val] ~= nil then
            raw[name] = raw[val]
        end
    end

    return raw
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Groupes mutuellement exclusifs (#if X == Y / #elif X == Y)
-- ─────────────────────────────────────────────────────────────────────────────
local function scan_conditions(root, defines)
    local function is_project_macro(s)
        return s:match("[%u][%u%d]*_[%u%d_]+") ~= nil
            and not IGNORE[s]
            and is_feature_flag(s, 1)
    end

    local groups = {}
    local files  = vim.fn.globpath(root, "**/*.c",  false, true)
    vim.list_extend(files, vim.fn.globpath(root, "**/*.h",  false, true))
    vim.list_extend(files, vim.fn.globpath(root, "**/*.cc", false, true))

    for _, file in ipairs(files) do
        if not should_skip_file(file) then
            for _, line in ipairs(vim.fn.readfile(file)) do
                local lhs, rhs = line:match(
                    "#e?l?if%s+([%u][%u%d_]+)%s*==%s*([%u][%u%d_]+)")
                if lhs and rhs
                    and is_project_macro(lhs)
                    and is_project_macro(rhs) then

                    if not groups[lhs] then groups[lhs] = {} end
                    local val = defines[rhs] or (#groups[lhs] + 1)
                    local already = false
                    for _, e in ipairs(groups[lhs]) do
                        if e.name == rhs then already = true; break end
                    end
                    if not already then
                        table.insert(groups[lhs], { name = rhs, value = val })
                    end
                end
            end
        end
    end

    return groups
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Ecriture du .clangd
-- Toujours écraser le fichier existant, même si vide
-- ─────────────────────────────────────────────────────────────────────────────
function M._write_clangd(root, chosen_flags, chosen_defines)
    local lines = {
        "# .clangd - genere automatiquement par Neovim",
        "CompileFlags:",
        "  Add:",
    }

    local sorted_flags = {}
    for name in pairs(chosen_flags) do
        table.insert(sorted_flags, name)
    end
    table.sort(sorted_flags)

    for _, name in ipairs(sorted_flags) do
        if chosen_defines[name] == nil then
            table.insert(lines, string.format("    - -D%s=1", name))
        end
    end

    local sorted_defines = {}
    for name, value in pairs(chosen_defines) do
        table.insert(sorted_defines, { name = name, value = value })
    end
    table.sort(sorted_defines, function(a, b) return a.name < b.name end)

    for _, m in ipairs(sorted_defines) do
        table.insert(lines, string.format("    - -D%s=%s", m.name, m.value))
    end

    local path = root .. "/.clangd"

    -- Toujours écrire, même si vide (pour effacer l'ancien contenu)
    if #lines == 3 then
        -- Fichier vide : juste l'entête sans macros
        vim.fn.writefile({ "# .clangd - genere automatiquement par Neovim" }, path)
        vim.notify(".clangd vide genere (aucune macro) -> " .. path, vim.log.levels.INFO)
    else
        vim.fn.writefile(lines, path)

        local all = {}
        for _, name in ipairs(sorted_flags) do
            if chosen_defines[name] == nil then
                table.insert(all, "-D" .. name .. "=1")
            end
        end
        for _, m in ipairs(sorted_defines) do
            table.insert(all, string.format("-D%s=%s", m.name, m.value))
        end

        vim.notify(
            string.format(".clangd genere (%d macros) :\n%s\n-> %s",
                #all, table.concat(all, "\n"), path),
            vim.log.levels.INFO
        )
    end

    restart_clangd()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Generation interactive
-- ─────────────────────────────────────────────────────────────────────────────
function M._do_generate(root)
    vim.schedule(function()
        local ifdef_macros, ifndef_macros = scan_ifdef_macros(root)
        local defines = scan_defines(root)
        local groups  = scan_conditions(root, defines)

        -- Retirer les macros #ifndef de ifdef_macros
        for name in pairs(ifndef_macros) do
            ifdef_macros[name] = nil
        end

        local chosen_flags   = {}  -- vide au départ, rempli par les questions
        local chosen_defines = {}

        -- Liste triée des macros #ifdef / #if defined() à proposer
        local all_optional = {}
        for name in pairs(ifdef_macros) do
            table.insert(all_optional, name)
        end
        table.sort(all_optional)

        local questions = {}

        -- 1. Macros #ifdef / #if defined() → tout, rien, ou une par une
        if #all_optional > 0 then
            table.insert(questions, {
                type   = "optional_group",
                macros = all_optional,
                prompt = string.format(
                    "Macros #ifdef / #if defined() (%d) : %s",
                    #all_optional,
                    table.concat(all_optional, ", ")
                ),
                choices = {
                    "Tout activer    (definir toutes → blocs #ifdef actifs)",
                    "Rien activer    (ne rien definir → blocs #else actifs)",
                    "Choisir une par une",
                },
            })
        end

        -- 2. Groupes mutuellement exclusifs (#if X == Y)
        for macro, choices in pairs(groups) do
            local labels = vim.tbl_map(function(c)
                return string.format("%-20s  (%s = %s)", c.name, macro, c.value)
            end, choices)
            table.insert(questions, {
                type         = "group",
                macro        = macro,
                choices_data = choices,
                prompt       = string.format("Branche active pour %s ?", macro),
                choices      = labels,
            })
        end

        local q_idx = 1

        local function ask_next()
            if q_idx > #questions then
                M._write_clangd(root, chosen_flags, chosen_defines)
                return
            end

            local q = questions[q_idx]

            -- ── Macros #ifdef / #if defined() ─────────────────────────────
            if q.type == "optional_group" then
                vim.ui.select(q.choices, { prompt = q.prompt }, function(_, i)
                    if i == 1 then
                        -- Tout activer
                        for _, name in ipairs(q.macros) do
                            chosen_flags[name] = true
                        end
                        q_idx = q_idx + 1
                        ask_next()

                    elseif i == 2 then
                        -- Rien activer → chosen_flags reste vide
                        q_idx = q_idx + 1
                        ask_next()

                    elseif i == 3 then
                        -- Choisir une par une
                        local m_idx = 1
                        local function ask_one()
                            if m_idx > #q.macros then
                                q_idx = q_idx + 1
                                ask_next()
                                return
                            end
                            local name = q.macros[m_idx]
                            vim.ui.select(
                                {
                                    string.format(
                                        "Oui  → -D%s=1  (active #ifdef/%s)",
                                        name, name),
                                    string.format(
                                        "Non  → non defini  (active #else)"),
                                },
                                { prompt = string.format("Activer %s ?", name) },
                                function(_, j)
                                    if j == 1 then
                                        chosen_flags[name] = true
                                    end
                                    m_idx = m_idx + 1
                                    ask_one()
                                end
                            )
                        end
                        ask_one()

                    else
                        -- Annulé → rien activer
                        q_idx = q_idx + 1
                        ask_next()
                    end
                end)

            -- ── Groupes mutuellement exclusifs (#if X == Y) ───────────────
            elseif q.type == "group" then
                vim.ui.select(q.choices, { prompt = q.prompt }, function(_, i)
                    if i then
                        local picked = q.choices_data[i]
                        chosen_defines[q.macro]     = picked.value  -- SCHED_POLICY = 1
                        chosen_defines[picked.name] = picked.value  -- SCHED_FIFO   = 1
                        chosen_flags[q.macro]       = nil
                        chosen_flags[picked.name]   = nil
                    end
                    q_idx = q_idx + 1
                    ask_next()
                end)
            end
        end

        ask_next()
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Entree publique
-- ─────────────────────────────────────────────────────────────────────────────
function M.generate()
    local root = vim.fs.dirname(vim.fs.find({
        'compile_commands.json', '.clangd', '.git', 'Makefile'
    }, { upward = true })[1])

    if not root then
        vim.notify("Racine du projet introuvable", vim.log.levels.ERROR)
        return
    end

    local clangd_path = root .. "/.clangd"
    if vim.fn.filereadable(clangd_path) == 1 then
        vim.ui.select(
            { "Oui, ecraser", "Non, annuler" },
            { prompt = ".clangd existe deja, ecraser ?" },
            function(choice)
                if choice == "Oui, ecraser" then M._do_generate(root) end
            end
        )
    else
        M._do_generate(root)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Setup
-- ─────────────────────────────────────────────────────────────────────────────
function M.setup()
    vim.api.nvim_create_user_command("ClangdGen", function()
        M.generate()
    end, { desc = "Generer .clangd depuis les macros du projet" })

    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*/.clangd",
        callback = function()
            vim.notify(
                "Restart clangd apres modification du .clangd",
                vim.log.levels.INFO
            )
            restart_clangd()
        end,
    })

    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "*.c", "*.h", "*.cc" },
        callback = function()
            local root = vim.fs.dirname(vim.fs.find({
                '.git', 'Makefile', 'compile_commands.json'
            }, { upward = true })[1])
            if not root then return end
            if vim.fn.filereadable(root .. "/.clangd") == 1 then return end

            for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
                if line:match("^%s*#if")
                    or line:match("^%s*#ifdef")
                    or line:match("^%s*#ifndef") then
                    vim.notify(
                        "Macros preprocesseur detectees -> :ClangdGen",
                        vim.log.levels.WARN
                    )
                    return
                end
            end
        end,
    })
end

return M
