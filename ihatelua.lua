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
---@param self Object
---@param object Object
---@return boolean
function Object:instanceOf(object)
    if (Object.id(self) == nil or Object.id(object) == nil) then error("Both arguments for 'instanceOf' must extend Object.", 2) end;
    if (Object.isClass(self) and Object.isInstance(object)) then error("A class (arg #1) cannot be an instance of an instance (arg #2).", 2) end;

    local targetID = getmetatable(Object.isClass(object) and object or object.class)['__id'];
    local class = Object.isClass(self) and self or self.class;
    while class do
        if (getmetatable(class)['__id'] == targetID) then return true end;
        class = class.super;
    end;

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

    ---@TODO Needs documenting.
    __len       = function() error("__len not yet implemented.") end;
    __pairs     = function() error("__len not yet implemented.") end;
    __ipairs    = function() error("__ipairs not yet implemented.") end;
    __gc        = function() error("__gc not yet implemented.") end;
    __unm       = function() error("__unm not yet implemented.") end;
    __add       = function() error("__add not yet implemented.") end;
    __sub       = function() error("__sub not yet implemented.") end;
    __mul       = function() error("__mul not yet implemented.") end;
    __div       = function() error("__div not yet implemented.") end;
    __idiv      = function() error("__idiv not yet implemented.") end;
    __mod       = function() error("__mod not yet implemented.") end;
    __pow       = function() error("__pow not yet implemented.") end;
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
    if (key == 'constructor') then
        if (type(value) ~= 'function') then error(string.format("Constructor for class '%s' must be a function. Actual type: '%s'.", Object.type(class), type(value))) end;
        getmetatable(class)['__constructor'] = value;
        return;
    end

    -- Anything that isn't the constructor is assumed to be an instance field/method.
    getmetatable(class)[type(value) == 'function' and '__iMethods' or '__iFields'][key] = value;
end;

Object_MetaFactory.Class__call = function(class, ...)
    local newInstance, parentInstance = getmetatable(class)['__constructor'](class, ...);

    if (type(newInstance) ~= 'table') then error(string.format("Class constructor '%s' must return a table for value #1. Actual type: '%s'.", Object.type(class), type(newInstance)), 2) end;
    
    if (parentInstance ~= nil) then
        if (type(parentInstance) ~= 'table') then error(string.format("Class constructor '%s' must return a table or nil for value #2. Actual type: '%s'.", Object.type(class), type(parentInstance)), 2) end;
        if (Object.id(parentInstance) == nil or Object.isInstance(parentInstance) == false) then error(string.format("The parent value returned in class constructor '%s' must extend Object and be an instance of a class.", Object.type(class)), 2) end;
    end

    parentInstance = parentInstance or (class.super ~= Object and class.super(...) or nil);
    local instanceMeta = Object_MetaFactory.createInstance(class, parentInstance);

    instanceMeta.__id = getTableID(newInstance);
    for key, value in pairs(getmetatable(class)['__iFields']) do newInstance[key] = value end; -- Copy all instance fields into the new instance table.

    return setmetatable(newInstance, instanceMeta);
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
        
        __len           = (meta and meta.__len)     or getmetatable(parent)['__len'];
        __pairs         = (meta and meta.__pairs)   or getmetatable(parent)['__pairs'];
        __ipairs        = (meta and meta.__ipairs)  or getmetatable(parent)['__ipairs'];
        __gc            = (meta and meta.__gc)      or getmetatable(parent)['__gc'];
        __unm           = (meta and meta.__unm)     or getmetatable(parent)['__unm'];
        __add           = (meta and meta.__add)     or getmetatable(parent)['__add'];
        __sub           = (meta and meta.__sub)     or getmetatable(parent)['__sub'];
        __mul           = (meta and meta.__mul)     or getmetatable(parent)['__mul'];
        __div           = (meta and meta.__div)     or getmetatable(parent)['__div'];
        __idiv          = (meta and meta.__idiv)    or getmetatable(parent)['__idiv'];
        __mod           = (meta and meta.__mod)     or getmetatable(parent)['__mod'];
        __pow           = (meta and meta.__pow)     or getmetatable(parent)['__pow'];
        -- -- -- -- -- -- -- --

        __index         = nil; -- Set during class initialisation.
        __newindex      = Object_MetaFactory.Class__newindex;
        __call          = Object_MetaFactory.Class__call;
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
        local iField = rawget(instance, key);
        if (iField) then return iField end; -- Check the instance for the field.

        iMethod = getmetatable(instance.class)['__iMethods'][key];
        if (iField) then return iField end; -- Check the class for instance methods.

        instance = instance.super;
    end;

    return Object[key];
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

        __len           = getmetatable(parentClass)['__len'];
        __pairs         = getmetatable(parentClass)['__pairs'];
        __ipairs        = getmetatable(parentClass)['__ipairs'];
        __gc            = getmetatable(parentClass)['__gc'];
        __unm           = getmetatable(parentClass)['__unm'];
        __add           = getmetatable(parentClass)['__add'];
        __sub           = getmetatable(parentClass)['__sub'];
        __mul           = getmetatable(parentClass)['__mul'];
        __div           = getmetatable(parentClass)['__div'];
        __idiv          = getmetatable(parentClass)['__idiv'];
        __mod           = getmetatable(parentClass)['__mod'];
        __pow           = getmetatable(parentClass)['__pow'];
        -- -- -- -- -- -- -- --

        __index         = Object_MetaFactory.Instance__index;
        __newIndex      = Object_MetaFactory.Instance__newindex;
    }
end;

return Object;
