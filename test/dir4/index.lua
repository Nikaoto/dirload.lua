local modules = {
   ["cur_variant1"] = dirload(),
   ["cur_variant2"] = dirload("."),
   ["cur_variant3"] = dirload("./"),
   ["cur_variant4"] = dirload(""),

   ["cur_variant5"] = dirload("/dir4/."),
   ["cur_variant6"] = dirload("/dir4/"),
   ["cur_variant7"] = dirload("/dir4"),
   
   ["sub_variant1"] = dirload("dir4_1"),
   ["sub_variant2"] = dirload("dir4_1/"),
   ["sub_variant3"] = dirload("dir4_1/."),

   ["sub_variant4"] = dirload("./dir4_1"),
   ["sub_variant5"] = dirload("./dir4_1/"),
   ["sub_variant6"] = dirload("./dir4_1/."),

   ["sub_variant7"] = dirload("/dir4/dir4_1"),
   ["sub_variant8"] = dirload("/dir4/dir4_1/"),
   ["sub_variant9"] = dirload("/dir4/dir4_1/."),
}

return modules
