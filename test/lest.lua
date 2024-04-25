-- lest.lua

local lest = {
   _VERSION = 'lest 0.0.1',
   _URL = 'http://github.com/Nikaoto/lest',
   _DESCRIPTION = 'Minimal testing library for Lua',
   _LICENSE = [[
      Simplified BSD License

      Copyright (c) 2020 Nika Otiashvili

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are
      met:

      1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

      2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
      A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
      HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   ]]
}

local color_green = "\27[32m"
local color_red = "\27[31m"
local color_bold = "\27[1m"
local color_end = "\27[0m"

local pass_prefix = color_green .. "PASS" .. color_end
local fail_prefix = color_red .. "FAIL" .. color_end
local fail_reason_indentation = " "

local line_cache = {}
local pass_count = 0
local fail_count = 0

-- Maximum length of x and y when printing "Expected x, got y" on failure
local str_max_log_len = 200

local function truncate_line(line, max)
   max = max or 110
   if #line > max then
      return line:sub(1, max - 3) .. "..."
   end
   return line
end

local function print_result(prefix, file_name, line_number, line_content)
   print(
      truncate_line(
         string.format(
            "%s %s:%i %s",
            prefix,
            file_name,
            line_number,
            line_content
         )
      )
   )
end

local function print_fail_reason(msg)
   print(string.format("%s%s", fail_reason_indentation, msg))
end

-- Return true if tbl1 subsets and supersets tbl2
local function table_equals(tbl1, tbl2)
   if type(tbl1) ~= "table" or type(tbl2) ~= "table" then
      return false
   end

   -- Check tbl1 subset of tbl2
   for k, v1 in pairs(tbl1) do
      local v2 = tbl2[k]

      -- Call comparison function if values are tables
      if type(v1) == "table" then
         if not table_equals(v1, v2) then
            return false
         end
      else
         if v1 ~= v2 then
            return false
         end
      end
   end

   -- Check tbl2 subset of tbl1
   -- Here we only need to check if keys that tbl2 has exist in tbl1
   -- because if we reached this line, that means each value at `key`
   -- in tbl1 was also present in tbl2 in the same location
   for k, _ in pairs(tbl2) do
      if tbl1[k] == nil then
         return false
      end

      -- No need to check for table comparison, because if v1 and v2
      -- are tables, that means they were compared in the previous
      -- loop and ended up equal
   end

   return true
end

-- Return true if tbl1 is a subset of tbl2, otherwise false
local function table_subsets(tbl1, tbl2)
   if type(tbl1) ~= "table" or type(tbl2) ~= "table" then
      return false
   end

   -- Check tbl1 values exist in tbl2 at the same keys
   for k, v1 in pairs(tbl1) do
      local v2 = tbl2[k]

      -- Check if child tables are subsets
      if type(v1) == "table" then
         if not table_equals(v1, v2) then
            return false
         end
      else
         if v1 ~= v2 then
            return false
         end
      end
   end

   return true
end

lest.expect = function(value)
   local info = debug.getinfo(2)
   local file_name = info.short_src
   local line_number = info.currentline

   -- Cache file lines
   if not line_cache[file_name] then
      local t = {}
      for line in io.lines(file_name) do
         t[#t + 1] = line:gsub("^ +", "")
      end
      line_cache[file_name] = t
   end

   local line_content = line_cache[file_name][line_number]

   return {
      to_be = function(expected_value)
         local equal

         if type(value) == "table" then
            equal = table_equals(value, expected_value)
         else
            equal = (value == expected_value)
         end

         if equal then
            pass_count = pass_count + 1
            print_result(pass_prefix, file_name, line_number, line_content)
         else
            fail_count = fail_count + 1
            print_result(fail_prefix, file_name, line_number, line_content)

            -- Print fail reason
            local value_type = type(value)

            --- Mismatched values
            local message
            if value_type == "table" then
               message = "Tables do not match"
            elseif value_type == "number" then
               message = string.format(
                  "Expected %.2f, got %.2f",
                  expected_value, value)
            else
               message = string.format(
                  "Expected %q, got %q",
                  truncate_line(tostring(expected_value), str_max_log_len),
                  truncate_line(tostring(value), str_max_log_len))
            end

            print_fail_reason(message)
         end
      end,

      -- When A subsets B, A is a subset of B, meaning B is a superset of A
      to_subset = function(superset_table)
         if type(value) ~= "table" or type(superset_table) ~= "table" then
            fail_count = fail_count + 1
            print_result(fail_prefix, file_name, line_number, line_content)
            print_fail_reason("to_subset() used on non-table value")
         else
            -- Check if value is a subset of superset_table
            if table_subsets(value, superset_table) then
               pass_count = pass_count + 1
               print_result(pass_prefix, file_name, line_number, line_content)
            else
               fail_count = fail_count + 1
               print_result(fail_prefix, file_name, line_number, line_content)
               print_fail_reason(string.format("%s is not a subset of %s", value, superset_table))
            end
         end
      end,
      ["not_"] = {
         to_be = function(expected_value)
            local equal

            if type(value) == "table" then
               equal = table_equals(value, expected_value)
            else
               equal = (value == expected_value)
            end

            if not equal then
               pass_count = pass_count + 1
               print_result(pass_prefix, file_name, line_number, line_content)
            else
               fail_count = fail_count + 1
               print_result(fail_prefix, file_name, line_number, line_content)

               -- Print fail reason
               local value_type = type(value)
               --- Mismatched types
               if value_type ~= type(expected_value) then
                  print_fail_reason("Types match")
                  return
               end

               --- Mismatched values
               local message
               if value_type == "table" then
                  message = "Tables match"
               elseif value_type == "number" then
                  message = string.format(
                     "Didn't expect %.2f, got %.2f",
                     expected_value, value)
               else
                  message = string.format(
                     "Didn't expect %q, got %q",
                     tostring(expected_value), tostring(value))
               end

               print_fail_reason(message)
            end
         end,

         -- When A subsets B, A is a subset of B, meaning B is a superset of A
         to_subset = function(superset_table)
            if type(value) ~= "table" or type(superset_table) ~= "table" then
               fail_count = fail_count + 1
               print_result(fail_prefix, file_name, line_number, line_content)
               print_fail_reason("to_subset() used on non-table value")
            else
               -- Check if value is a subset of superset_table
               if not table_subsets(value, superset_table) then
                  pass_count = pass_count + 1
                  print_result(pass_prefix, file_name, line_number, line_content)
               else
                  fail_count = fail_count + 1
                  print_result(fail_prefix, file_name, line_number, line_content)
                  print_fail_reason(string.format("%s is a subset of %s", value, superset_table))
               end
            end
         end,
      }
   }
end

lest.group = function(group_name, func)
   print("\n" .. color_bold .. group_name .. color_end)
   if func then
      func()
   end
end

lest.get_stats = function()
   return {
      fail = fail_count,
      pass = pass_count,
      total = pass_count + fail_count
   }
end

lest.reset_stats = function()
   fail_count = 0
   pass_count = 0
end

lest.print_stats = function()
   local total_count_string = string.format("%i Total", pass_count + fail_count)
   local passed_count_string = string.format("%i Passed", pass_count)
   local failed_count_string = string.format("%i Failed", fail_count)

   local stats_string = string.format(
      " %s  %s  %s ",
      total_count_string,
      passed_count_string,
      failed_count_string
   )

   local line_of_dashes = string.rep("-", string.len(stats_string))
   print(line_of_dashes)
   print(stats_string)
   print(line_of_dashes)
end

return lest
