-- This file only exists here for love2d compatibility.
-- So you can run the tests from love2d using `love .` from the test/ directory.

function love.load()
   require("run_tests")
   love.event.quit()
end

function love.update(dt)
end

function love.draw()
end
