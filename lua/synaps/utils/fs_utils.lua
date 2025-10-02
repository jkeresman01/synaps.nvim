local uv = vim.loop
local M = {}

local function has_marker(path, marker)
    return uv.fs_stat(path .. "/" .. marker) ~= nil
end

local function is_project_root(path)
    local markers = { ".git", "package.json", "pyproject.toml" }
    for _, m in ipairs(markers) do
        if has_marker(path, m) then
            return true
        end
    end
    return false
end

local function parent(path)
    return vim.fn.fnamemodify(path, ":h")
end

function M.get_project_root()
    local path = vim.fn.getcwd()
    while path and path ~= "/" do
        if is_project_root(path) then
            return path
        end
        path = parent(path)
    end
    return vim.fn.getcwd()
end

local function read_file(path)
    local fd = uv.fs_open(path, "r", 438)
    if not fd then
        return nil
    end
    local stat = uv.fs_fstat(fd)
    local data = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)
    return data
end

local function insert_file(files, path, data)
    table.insert(files, { path = path, contents = data })
end

local function scan_dir(dir, max, files, count)
    local handle = uv.fs_scandir(dir)
    if not handle then
        return
    end
    while true do
        local name, type = uv.fs_scandir_next(handle)
        if not name or count[1] >= max then
            return
        end
        local full = dir .. "/" .. name
        if type == "file" then
            local data = read_file(full)
            if data then
                insert_file(files, full, data)
                count[1] = count[1] + 1
            end
        elseif type == "directory" and name ~= ".git" then
            scan_dir(full, max, files, count)
        end
    end
end

function M.scan_project(max_files)
    local files, count = {}, { 0 }
    scan_dir(M.get_project_root(), max_files, files, count)
    return files
end

return M
