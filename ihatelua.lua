local inspect = function(root) return require('inspect')(root, { indent = "   |" }) end;

-- Lua Functions ----------------------------------------
local getmetatable, setmetatable = getmetatable, setmetatable;
local rawget, rawset = rawget, rawset;
local tostring = tostring;
---------------------------------------------------------


---Get the unique ID of a table.
---@param table table
---@return string
local function getTableID(table)
    local r = tostring(table):gsub("table: ", "", 1);;
    return r;
end;


---@class Object
local Object = {};
local Object_Meta = { __type = "$Object" };
local Object_MetaFactory = {};


-- Global Functions -------------------------------------
---Create a new class, extending another.
---@generic O, T:Object
---@param self T
---@param name string @The name of the new clas. Can be en empty string or nil of no meta is provided.
---@param meta? UserMeta @A table of metamethods to use for this class and its instances.
---@return O
function Object:Extend(name, meta)




    name, meta = name or "", meta or {};



    return nil;
end;

---Get the type of the object; otherwise known as the class.  
---If no type is found, the object is considered invalid, and `nil` is returned.
---@param self Object
---@return nil|string
function Object:type()
    local mt = getmetatable(self);
    return (mt and mt['__type']) or nil;
end;

---Check if this object is a class.
---@return boolean
function Object:isClass()
    local mt = getmetatable(self);
    return (mt and mt['__isClass']) or false;
end;

---Check if this object is an instance of a class.
---@return boolean
function Object:isInstance()
    local mt = getmetatable(self);
    return (mt and mt['__isInstance']) or false;
end;
---------------------------------------------------------


-- User Meta --------------------------------------------
---@class UserMeta
---@field __tostring fun(object)
---@field __concat fun(prefix, object)
local Object_DefaultMeta = {
    __tostring  = function(object) return string.format("[%s: %s]", Object.isClass(object) and "Class" or "Object", Object.type(object)) end;
    __concat    = function(prefix, object) return string.format("[%s%s]", prefix, tostring(object)) end;
};

for key,value in pairs(Object_DefaultMeta) do Object_Meta[key] = value end;
setmetatable(Object, Object_Meta);
---------------------------------------------------------

-- Factory ----------------------------------------------

--Writes to the class table instead, when 'Class.static' is used.
Object_MetaFactory.StaticWriter = function(env, key, value)
    rawset(getmetatable(env)['__class'], key, value);
end;

function Object_MetaFactory.createStaticEnv(class)
    local env = {};
    local meta = {
        __class = class;
        __newindex = Object_MetaFactory.StaticWriter;
        __index = class.super;
    };
    return setmetatable(env, meta);
end;

-- -- -- -- Class -- -- -- --

Object_MetaFactory.Class__constructor = function() return {} end;

Object_MetaFactory.Class__newindex = function(class, key, value)
    if (key == 'super' or key == 'static') then error(string.format("Cannot assign reserved keyword '%s' in class '%s'.", key, Object.type(class)), 2) end;

    -- Set the constructor.
    if (key == '__constructor') then
        if (type(value) ~= 'function') then error(string.format("Constructor for class '%s' must be a function. Actual type: '%s'.", Object.type(class), type(value))) end;
        getmetatable(class)['__constructor'] = value;
        return;
    end

    -- Anything that isn't the constructor is assumed to be an instance field/method.
    getmetatable(class)[type(value) == 'function' and '__iMethods' or '__iFields'] = value;
end;

function Object_MetaFactory.createClass(parent, name, meta)
    return {
        __isClass       = true;
        __type          = name;
        __super         = parent;
        __constructor   = Object_MetaFactory.Class__constructor; -- Default constructor.

        -- Instance stuff -- --
        __iFields       = {};
        __iMethods      = setmetatable({}, { __index = getmetatable(parent)['__iMethods'] });
        -- -- -- -- --- -- ----

        -- UserMeta -- -- -- --
        ---@TODO zug zug
        -- -- -- -- -- -- -- --

        --__static -- Set during class initialisation.
        --__index -- Set during class initialisation.
        __newindex      = Object_MetaFactory.Class__newindex.Class__newindex;
    }
end;

---------------------------------------------------------




