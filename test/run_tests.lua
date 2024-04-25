-- This file MUST be launched from the "test" directory as cwd

package.path = package.path .. ";../?.lua"

local lest = require("lest")
local expect = lest.expect
local group = lest.group

inspect = require("inspect") -- Only used when debugging
dirload = require("dirload")

-- Load local lfs_ffi when run with just luajit
if not love or not love.filesystem then
   lfs_ffi = require("lfs_ffi")
end

group("require() an index file that uses dirload()", function()
   local dir1_modules = require("dir1/index")

   expect(dir1_modules).to_be({
      ["module1"] = require("dir1/module1"),
      ["module2"] = require("dir1/module2"),
   })
end)

group("dirload() all modules directly", function()
   local dir2_modules = dirload("dir2")

   expect(dir2_modules).to_be({
      ["module1"] = require("dir2/module1"),
      ["module2"] = require("dir2/module2"),
   })
end)

group("dirload() with path variations", function()
   local dir2_modules = {
      ["module1"] = require("dir2/module1"),
      ["module2"] = require("dir2/module2"),
   }

   expect(dir2_modules).to_be(dirload("dir2"))
   expect(dir2_modules).to_be(dirload("./dir2"))
   expect(dir2_modules).to_be(dirload("./dir2/"))
   expect(dir2_modules).to_be(dirload("dir2/"))
   expect(dir2_modules).to_be(dirload("/dir2/"))
end)

group(
   "require() an index file that uses dirload() with path variations",
   function()
      local dir4_cur_modules = {
         ["module1"] = require("dir4/module1"),
         ["module2"] = require("dir4/module2"),
      }

      local dir4_sub_modules = {
         ["module3"] = require("dir4/dir4_1/module3"),
         ["module4"] = require("dir4/dir4_1/module4"),         
      }

      local dir4_modules = {
         ["cur_variant1"] = dir4_cur_modules,
         ["cur_variant2"] = dir4_cur_modules,
         ["cur_variant3"] = dir4_cur_modules,
         ["cur_variant4"] = dir4_cur_modules,
         ["cur_variant5"] = dir4_cur_modules,
         ["cur_variant6"] = dir4_cur_modules,
         ["cur_variant7"] = dir4_cur_modules,

         ["sub_variant1"] = dir4_sub_modules,
         ["sub_variant2"] = dir4_sub_modules,
         ["sub_variant3"] = dir4_sub_modules,
         ["sub_variant4"] = dir4_sub_modules,
         ["sub_variant5"] = dir4_sub_modules,
         ["sub_variant6"] = dir4_sub_modules,
         ["sub_variant7"] = dir4_sub_modules,
         ["sub_variant8"] = dir4_sub_modules,
         ["sub_variant9"] = dir4_sub_modules,
      }

      expect(require("dir4/index")).to_be(dir4_modules)
   end
)

group("index file name collision", function()
   local dir5_modules = {
      ["cur"] = {
         ["module1"] = require("dir5/module1"),
         ["module2"] = require("dir5/module2"),
      },
      ["sub"] = {
         -- This index file should get loaded as a module
         ["index"]   = require("dir5/dir5_1/index"),
         ["module3"] = require("dir5/dir5_1/module3"),
         ["module4"] = require("dir5/dir5_1/module4"),
      }
   }

   expect(require("dir5/index")).to_be(dir5_modules)
end)

group("ignore files", function()
   local dir1_modules = {
      ["module2"] = require("dir1/module2")
   }

   expect(dirload("dir1", {
      ignore = {"module1.lua", "index.lua"}
   })).to_be(dir1_modules)
end)

lest.print_stats()
