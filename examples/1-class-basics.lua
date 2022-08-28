local Object = require('ihatelua');

-----------------------------------------------------------

-- Create a new class.
local MyClass = Object:Extend("MyClass");

-- Class names are not required, nor do they have to be unique.
-- If left blank or nil, it will be replaced my the table ID that represents it.
-- local MyClass = Object:Extend( ["" or nil] );


-- Create a new class, extending another.
local MyOtherClass = MyClass:Extend("MyOtherClass");


-- STATIC FIELDS ----------------------------------------------------


-- Static fields & methods are declared using [Class].static.[index]
MyClass.static.foo1 = "bar1";
MyClass.static.foo2 = "bar2";


-- Once defined, static fields & methods can be referenced directly without having to index 'static'.
print(MyClass.foo1); -- >> "bar1"


-- Classes will inherit any parent fields & methods that they extend from.
print(MyOtherClass.foo2); -- >> "bar2"


-- New fields & methods will be written to the referenced class. Parent indexes will remain unaltered.
MyOtherClass.static.foo1 = "overridden bar1";
print(MyClass.foo1);        -- >> "bar1"
print(MyOtherClass.foo1);   -- >> "overridden bar1"


--- Static methods are defined and follow the same rules as fields.
function MyClass.static:staticFunction()
    -- self is a reference to the class.
end;


-- INSTANCE FIELDS --------------------------------------------------


-- Instance fields are defined without indexing 'static'. They are not accessible from the class.
MyClass.color = "red";


-- Instance methods are defined without indexing 'static'. They are not accessible from the class. 
function MyClass:instanceMethod()
    -- self is a reference to the instance it was called from.
end;


-- Instance fields will be copied to each new instnce of the class
local firstInstance = MyClass();
firstInstance.color = "blue"
local secondInstance = MyClass();

print(firstInstance.color);     -- >> "blue"
print(secondInstance.color);    -- >> "red"

--[[

[ ** IMPORTANT NOTE ** ]

Take care when creating static/instance fields & methods with the same name.
In such a case, instance fields should be written *first*, and static fields second.

Why:
  MyClass.static.foo = "bar"; -- Create a static field.
  MyClass.foo = "overwritten bar"; -- Create an instance field.

  - `foo` can be indexed in MyClass.
  - `MyClass.foo = _` will overwrite it instead of creating an instance field.

]]

---------------------------------------------------------------------




