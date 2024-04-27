-- Require all .lua files from a given directory.
-- Does not traverse directories inside of directories.
-- Uses love.filesystem or lfs (luafilesystem). Whichever is available.

local function get_directory_items(path, caller_dir)
   -- Use love.filesystem
   if love and love.filesystem and love.filesystem.getDirectoryItems then
      return love.filesystem.getDirectoryItems(path)
   end

   -- Use luafilesystem
   local lfs = lfs or lfs_ffi
   if lfs then
      local cwd = lfs.currentdir()

      if path:sub(1, 1) == "/" or path == "" then
         path_for_lfs = cwd .. path
      elseif path == "." then
         path_for_lfs = cwd .. caller_dir
      end

      local dirlisting = {}
      local iter, dir_obj = lfs.dir(path_for_lfs)
      local dir = iter(dir_obj)
      while dir do
         if dir ~= "." and dir ~= ".." then
            table.insert(dirlisting, dir)
         end
         dir = iter(dir_obj)
      end
      return dirlisting
   end

   error("Neither love.filesystem nor lfs found.")
end

-- Returns the directory and the file name.
-- The returned directory path is relative to the directory that lua/love2d was
-- launched from. That directory will be returned as the root "/".
local function get_dirload_caller_path()
   local path = debug.getinfo(3, "S").source:sub(2)
   local dir = path:match("(.*/)") or "/"
   local file = path:match("([^/]+)$") or path
   local norm_dir, _ = dir:gsub("\\", "/")

   -- Remove leading "./"
   if norm_dir:sub(1, 2) == "./" then
      norm_dir = norm_dir:sub(3)
   end

   -- Append leading "/"
   if norm_dir:sub(1, 1) ~= "/" then
      norm_dir = "/" .. norm_dir
   end

   return norm_dir, file
end

local function dirload(rel_dir_path, opts)
   opts = opts or {}

   -- Create ignore table
   local ignore_tbl = {}
   if opts.ignore then
      for _, f in pairs(opts.ignore) do
         ignore_tbl[f] = true
      end
   end

   if rel_dir_path then
      -- Normalize backslashes
      rel_dir_path = rel_dir_path:gsub("\\", "/")

      if rel_dir_path == "./" or rel_dir_path == "." then
         rel_dir_path = ""
      elseif rel_dir_path ~= "" then
         -- Remove leading "./"
         if rel_dir_path:sub(1, 2) == "./" then
            rel_dir_path = rel_dir_path:sub(3)
         end

         -- Remove trailing "/."
         if rel_dir_path:sub(-2) == "/." then
            rel_dir_path = rel_dir_path:sub(1, -3)
         end

         -- Append trailing "/"
         if rel_dir_path:sub(-1) ~= "/" then
            rel_dir_path = rel_dir_path .. "/"
         end
      end
   else
      rel_dir_path = ""
   end

   local caller_dir, caller_file = get_dirload_caller_path()
   local path

   -- Relative to root
   if rel_dir_path:sub(1, 1) == "/" then
      path = rel_dir_path
   else
      -- Relative to caller script
      path = caller_dir .. rel_dir_path
   end

   -- Prevents requiring the same file that called dirload(). Also prevents
   -- ignoring a file with the same name as the caller in a different directory
   local check_caller_file_collision = (caller_dir == path)

   --[[
   print("path:", path)
   print("caller_dir:", caller_dir)
   print("rel_dir_path:", rel_dir_path)
   print(inspect(get_directory_items(path, caller_dir)))
   print()
   print()
   --]]

   local index = {}
   for _, file in pairs(get_directory_items(path, caller_dir)) do
      local ignored = ignore_tbl[file] or
          (check_caller_file_collision and (file == caller_file))

      if (not ignored) and file:match(".*%.lua$") then
         local module_name = file:gsub("%.lua$", "") 
         local succ, ret = pcall(require, path .. module_name)
         if succ then
            index[module_name] = ret
            if opts.on_load then opts.on_load(path, file, ret) end
         else
            print(string.format("Error loading \"%s\": %s", file, ret))
            if opts.on_error then opts.on_error(path, file, ret) end
         end
      end
   end

   return index
end

return dirload
