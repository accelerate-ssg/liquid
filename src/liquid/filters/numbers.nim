# Rounds a number to the nearest integer or to a specified number of decimal places
round : number [precision:number]

# Returns the absolute value of a number
abs : number

# Adds two numbers together
plus : number value:number

# Subtracts one number from another
minus : number value:number

# Multiplies a number by another number
times : number value:number

# Divides a number by another number
divided_by : number value:number

# Returns the remainder of a division operation
modulo : number value:number

# Returns a number formatted as a string with thousands separators
number_with_delimiter : number

# Returns a number formatted as a string with thousands separators and decimal places
number_with_precision : number precision:number

# Formats a number as a currency string
money : number

# Formats a number as a currency string with no decimal places
money_without_currency : number

# Formats a number as a currency string with no decimal places or currency symbol
money_without_trailing_zeros : number

# Returns a number formatted as a string with no decimal places
number_to_percentage : number

# Returns a number formatted as a string with a specified number of decimal places
number_to_human_size : number
