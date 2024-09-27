local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

--helper function for checking if a table contains a value
local function contains(table, value)
    for _, table_value in ipairs(table) do
        if table_value == value then
            return true
        end
    end
    return false
end

-- helper function for finding a filename in a directory which matches
-- a given pattern
local function find_file(directory, pattern)
    local filename_found = ""
    local pfile = io.popen('ls "' .. directory .. '"')

    if (pfile == nil) then
        return ""
    end

    for filename in pfile:lines() do
        if (string.find(filename, pattern) ~= nil) then
            filename_found = filename
            break
        end
    end
    return filename_found
end

-- gathers all of the bemol-generated files and adds them to the LSP workspace (for zon only)
local function bemol()
    local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
    local ws_folders_lsp = {}
    if bemol_dir then
        local file = io.open(bemol_dir .. "/ws_root_folders", "r")
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line)
            end
            file:close()
        end

        for _, line in ipairs(ws_folders_lsp) do
            if not contains(vim.lsp.buf.list_workspace_folders(), line) then
                vim.lsp.buf.add_workspace_folder(line)
            end
        end
    end
end

local jdtls = require 'jdtls'
local jdtls_setup = require 'jdtls.setup'

local home = os.getenv('HOME')
local root_markers = ''--ROOT_MARKERS_BLOCK
local root_dir = jdtls_setup.find_root(root_markers)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
local path_to_jdtls = "JDTLS_PATH_BLOCK/share/java/jdtls"
local path_to_config = home .. "/.cache/jdtls/config" 
local path_to_lombok = "LOMBOK_PATH_BLOCK/share/java/lombok.jar"
local path_to_plugins = path_to_jdtls .. "/plugins/"
local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")

local config = {
    cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xms1g",
        "-javaagent:" .. path_to_lombok,
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        "-jar",
        path_to_jar,

        "-configuration",
        path_to_config,

        "-data",
        workspace_dir,
    },

    root_dir = root_dir,

    capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = default_capabilities.textDocument,
    },

    settings = {
        java = {
            references = {
                includeDecompiledSources = true
            },
            eclipse = {
                downloadSources = true,
            },
            maven = {
                downloadSources = true,
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999
                }
            },
        }
    },

    --BEMOL_ON_ATTACH_BLOCK
}

jdtls.start_or_attach(config)
