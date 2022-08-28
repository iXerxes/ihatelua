local Object = require('ihatelua');

local tinsert = table.insert;

local SortedArray = Object:Extend("SortedArray");

function SortedArray:constructor(sortFunction)
    local newSortedArray = {
        store = {};

        activeSort = false;
        sorter = sortFunction;
    };
    return newSortedArray;
end;