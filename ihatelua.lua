local inspect = function(root, depth) return require('inspect')(root, { indent = "   |", depth = depth }) end;

-- Lua Functions ----------------------------------------
local getmetatable, setmetatable = getmetatable, setmetatable;
local rawget, rawset = rawget, rawset;
local tostring = tostring;
---------------------------------------------------------


---Get the unique ID of a table.
---@param table table
---@return string
local function getTableID(table)
    local r = tostring(table):gsub("table: ", "", 1);
    return r;
end;


---@class Object
---@field super nil|Object @A reference to the parent class or instance.
---@field static table @A reference to the proxy for static definitions. Only accessible from a class.
---@field class nil|Object @A reference to the parent class of an instance. Only accessible from an instace.
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

    local class = {};
    local classID = getTableID(class);
    local classMeta = Object_MetaFactory.createClass(self, name == "" and classID or name, meta);

    -- Initialise the class.
    classMeta.__id = classID;
    classMeta.__static = Object_MetaFactory.createStaticEnv(class);
    classMeta.__index = setmetatable({ super = classMeta.__super; static = classMeta.__static }, { __index = classMeta.__super });

    return setmetatable(class, classMeta);
end;

---Get the unique ID of the object. The is the table ID of the top-most table that represents the object.  
---If no ID is found, the object is considered invalid, and `nil` is returned.
---@param self Object
---@return nil|string
function Object:id()
    local mt = getmetatable(self);
    return (mt and mt['__id']) or nil;
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

---Check if an object is an instance of another object.
---`Class:instanceOf(instance)` will always return false.
---@param object any
---@return boolean
function Object:instanceOf(object)
    local objectID = Object.id(getmetatable((Object.isClass(object) and object or object.class)));
    local class = Object.isClass(self) and self or getmetatable(self)['__class'];
    while class do
        if (Object.id(class) == objectID) then return true end;
        class = class.super;
    end
    return false;
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

--Writes to the class table, when 'Class.static' is used.
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

-- -- -- Class -- -- -- -- --

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
    getmetatable(class)[type(value) == 'function' and '__iMethods' or '__iFields'][key] = value;
end;

function Object_MetaFactory.createClass(parent, name, meta)
    return {
        __isClass       = true;

        __id            = nil; -- Set during class initialisation.
        __type          = name;
        __super         = parent;
        __constructor   = Object_MetaFactory.Class__constructor; -- Default constructor.

        -- -- -- -- -- -- -- --
        __static        = nil; -- Set during class initialisation.
        __iFields       = {};
        __iMethods      = {};
        -- -- -- -- -- -- -- --

        -- UserMeta -- -- -- --
        __tostring      = meta.__tostring or getmetatable(parent).__tostring;
        __concat        = meta.__concat or getmetatable(parent).__concat;
        ---@TODO zug zug
        -- -- -- -- -- -- -- --

        __index         = nil; -- Set during class initialisation.
        __newindex      = Object_MetaFactory.Class__newindex;
    }
end;

-- -- -- Instance -- -- -- -- --

Object_MetaFactory.Instance__index = function(instance, key)
    if (key == 'class') then return getmetatable(instance)['__class'] end;
    if (key == 'super') then return getmetatable(instance)['__super'] end;

    local iMethod = getmetatable(instance.class)['__iMethods'][key]; -- Check the table of instance methods.
    if (iMethod) then return iMethod end;

    -- Crawl the inheritance chain, indexing each parent and its instance methods.
    instance = instance.super;
    while instance do
        local iField = rawget(instance, key); if (iField) then return iField end; -- Check the instance for the field.
        iMethod = getmetatable(instance.class)['__iMethods'][key]; if (iField) then return iField end; -- Check the class for instance methods.
        instance = instance.super;
    end;

    return nil;
end;

Object_MetaFactory.Instance__newindex = function(instance, key, value)
    if (key == 'class' or key == 'super') then error(string.format("Cannot assign reserved keyword '%s' in instance '%s'.", key, Object.type(instance)), 2) end;

    -- Don't redefine inherited instance methods. Just override them.
    if (type(value) == 'function') then rawset(instance, key, value) end;

    -- Find any inherited fields and redefine them.
    local oi = instance; instance = instance.super;
    while instance do
        local iField = rawget(instance, key);
        if (iField) then rawset(instance, key, value); return end;
        instance = instance.super;
    end;

    -- No field by this name was inherited. Set the key in the original instance.
    rawset(oi, key, value);
    return;
end;

function Object_MetaFactory.createInstance(parentClass, parentInstance)
    return {
        __isInstance    = true;

        __id            = nil; -- Set during instance initialisation.
        __type          = getmetatable(parentClass)['__type'];
        __class         = parentClass;
        __super         = parentInstance;

        -- UserMeta -- -- -- --
        __tostring      = getmetatable(parentClass)['__tostring'];
        __concat        = getmetatable(parentClass)['__concat'];
        ---@TODO zug zug
        -- -- -- -- -- -- -- --

        __index         = Object_MetaFactory.Instance__index;
        __newIndex      = Object_MetaFactory.Instance__newindex;
    }
end;

---------------------------------------------------------



local Class1 = Object:Extend("");
Class1.static.foo = "bar";
local Class2 = Class1:Extend("Class2");
local Class3 = Class2:Extend("Class3");

print("\n------------------------------------------------------------\n");

print(inspect(Class1, 3));

print("\n------------------------------------------------------------\n");

print("Class1.foo: " .. Class1.foo);
print("Class3.foo: " .. Class3.foo);

print("\n------------------------------------------------------------\n");

