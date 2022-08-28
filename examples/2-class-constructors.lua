local Object = require('ihatelua');

---------------------------------------------------------------------

--[[

    By default, a constructor is not required.

    Any instance fields can be created:
        - In the class, as an instance field, which are coped to any new instances of a class.
        - Directly to the new instance, after it has been created.

]]


-- Create a new class.
local Person = Object:Extend("Person");
local Employee = Object:Extend("Person");


-- Typical Usage ----------------------------------------------------

-- 1 value is returned that represents the body of the new instance.

function Person:constructor(name)
    local newPerson = {
        name = name;
    };
    return newPerson;
end

function Employee:constructor(name, job)
    local newEmployee = {
        job = job;
    };
    return newEmployee; -- self.super(name, job) is called automatically.
end

-- Returning only the instance body means the parent instance is automatically made by calling super(...).

local newPerson, newEmployee = Person("Bob"), Employee("John", "Engineer");
print("Hello, my name is .. " .. newPerson.name);
print("Hello, my name is .. " .. newEmployee.name ". My job is: " .. newEmployee.job .. ".");

---------------------------------------------------------------------



-- Special Usage ----------------------------------------------------

-- A second value can be returned if you want to have more control over the instance parent.

-- function Person:constructor(name)
--     local newPerson = {
--         name = name;
--     };
--     return newPerson;
-- end

-- function Employee:constructor(name, job)
--     local newEmployee = {
--         job = job;
--     };
--     return newEmployee, self.super("[Employee] " .. name);
-- end

-- local newPerson, newEmployee = Person("Bob"), Employee("John", "Engineer");
-- print("Hello, my name is .. " .. newPerson.name);
-- print("Hello, my name is .. " .. newEmployee.name ". My job is: " .. newEmployee.job .. ".");

---------------------------------------------------------------------