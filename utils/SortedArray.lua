local Object = require('ihatelua');
local inspect = function(root, depth) return require('inspect')(root, { indent = "   |", depth = depth }) end;

local tinsert = table.insert;


local SortedArray = Object:Extend("SortedArray",{
    __len = function(array) return #array.store end; -- Lua 5.2+
});

---Create a new array that sort
---@param aciveSort boolean @Whether this array will actively call the sort function each time a value is pushed to it.
---@param sortFunction function(a, b)
---@return Object
function SortedArray:constructor(aciveSort, sortFunction)
    local newSortedArray = {
        store = { };
        active = aciveSort or false;
        sorter = sortFunction;
    };
    return newSortedArray;
end;

---Get the current number of elements this array holds.
---@return integer
function SortedArray:size()
    return #self.store;
end;

---Manually trigger a sort.
---@return Object
function SortedArray:sort()
    table.sort(self.store, self.sorter);
    return self;
end;

---Set whether this array actively sorts elements as they are added.
---@param activeSort? boolean
---@return Object
function SortedArray:setActiveSort(activeSort)
    self.active = (activeSort == nil) and true or false;
    return self;
end;

---Check if active sort is enabled.
---@return boolean
function SortedArray:isActiveSort()
    return self.active;
end;

---Add a new item to the array.
---@param item any
---@return Object
function SortedArray:add(item)
    table.insert(self.store, item);
    if (self.active) then self:sort() end;
    return self;
end;