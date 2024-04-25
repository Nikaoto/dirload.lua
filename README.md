# dirload.lua
Require every `.lua` file in a given directory and return a table that contains
each loaded module.

## Example
If you have something like:
```
game/
  main.lua
  players/
    mario.lua
    luigi.lua
  enemies/
    goomba.lua
    koopa_troopa.lua
    bullet_bill.lua
    hammer_bro.lua
  utils/
    math.lua
    physics.lua
```

Ever just wanted to do this from `main.lua`?
```lua
require("utils/*")
local players = require("players/*")
local enemies = require("enemies/*")
```

In addition to `utils/math` and `utils/physics` being loaded, you'd expect to
get something like this:
```
players = {
    mario = {...},
    luigi = {...},
}

enemies = {
    goomba = {...},
    koopa_troopa = {...},
    bullet_bill = {...},
    hammer_bro = {...},
}
```

Well, with `dirload` you can!
```lua
-- from main.lua
dirload("utils")
local players = dirload("players")
local enemies = dirload("enemies")

-- The 3 lines above are equivalent to the code below
require("utils/math")
require("utils/physics")
local players = {
   mario = require("players/mario"),
   luigi = require("players/luigi"),
}
local enemies = {
   goomba = require("enemies/goomba"),
   koopa_troopa = require("enemies/koopa_troopa"),
   bullet_bill = require("enemies/bullet_bill"),
   hammer_bro = require("enemies/hammer_bro"),
}

```

## Usage
Copy `dirload.lua` into your codebase and do:
```lua
local dirload = require("dirload")

local modules = dirload("my_directory_with_modules/")
```

Dirload requires either [love2d](https://love2d.org) or
[luafilesystem](https://luarocks.org/modules/hisham/luafilesystem) to be loaded. The `dirload()` function will use whichever is available to get a dirlisting:
   - `love.filesystem.getDirectoryItems()`
   - `lfs.dir()`
   - `lfs_ffi.dir()`

### Arguments
The function takes 2 arguments `dirload(path, opts)`.

#### `path`
This is the relative path of the directory you want to load. Each `.lua` file
inside that directory will get required one by one and their contents will be
put into a table and returned.

- Directory separators must be forward slashes (`"dir0/dir1"`)

- If this is `nil` or `"."` or `"./"` or `""` then the current directory will be
  loaded. Obviously, the calling file will get ignored during the loading so we
  don't end up with an infinite loop that keeps dirloading the same file.

- A leading slash (i.e. `"/dir1"`) will tell dirload to load the directory
  relative to the root of the lua process. In other words, the root is the
  current working directory, from which the lua process was started.

#### `opts`
This is an object that can have the following key-values:
```lua
{
   -- A list of filenames to ignore (".lua" suffix is required!)
   ignore = {"something.lua", "another.lua"},

   -- Called when a module is loaded
   on_load = function(path, file_name, module)
      print(path, file_name, module)
   end,

   -- Called when an error is encountered while loading a module
   on_error = function(path, file_name, err)
      print(path, file_name, err)
   end,
}
```
  
## Caveats
When making a simple `index.lua` file the purpose of which is to simply export
all the modules in its directory, you must assign the result to a variable like
this:
```lua
-- index.lua
local modules = dirload()
return modules
```

Simply doing `return dirload()` won't work. This is probably because a direct
return folds the call stack level which then results in `debug.getinfo`
returning the wrong result when dirload is trying to find the relative path from
its caller.

## Running tests

### Love2D
```
cd test/
love .
```

### LuaJIT
```
cd test/
luajit run_tests.lua
```

This will use the `lfs_ffi.lua` module from inside the `test/` directory, so
running it with just lua won't work, it needs luajit's ffi.

## License
MIT
