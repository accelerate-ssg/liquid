# Returns the first element of an array
first : array

# Returns the last element of an array
last : array

# Joins the elements of an array into a string separated by a delimiter
join : array delimiter:string

# Returns the size of an array
size : array

# Sorts an array of strings in ascending order
sort : array

# Sorts an array of objects by a property in ascending order
sort : array property:string

# Sorts an array of strings in descending order
reverse : array

# Maps an array of objects to an array of values from a specified property
map : array property:string

# Removes duplicate elements from an array
uniq : array

# Returns a slice of an array
slice : array start:number [length:number]

# Removes all occurrences of a specified element from an array
where : array property:string value:string
