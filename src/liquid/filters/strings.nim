import strutils, base64, xmltree, json, sequtils, re

import ../shared

# Appends a string to another string
#append : string suffix:string
create_filter:
  proc append(input: string, suffix: string): string =
    result = input & suffix

# Converts a string into a base64-encoded string
#base64_decode : string
create_filter:
  proc base64_decode(input: string): string =
    result = input.decode()

# Converts a base64-encoded string into a string
#base64_encode : string
create_filter:
  proc base64_encode(input: string): string =
    result = input.encode()

# Converts a string into a URL-safe base64-encoded string
#base64_url_safe_decode : string
create_filter:
  proc base64_url_safe_decode(input: string): string =
    result = input.decode()

# Converts a URL-safe base64-encoded string into a string
#base64_url_safe_encode : string
create_filter:
  proc base64_url_safe_encode(input: string): string =
    result = input.encode(safe = true)

##
# Capitalizes the first word in a string and downcases the remaining characters.
# capitalize : string
# returns string
##
create_filter:
  proc capitalize(input: string): string =
    result = input.toLower()
    result = result[0..1].toUpper() & result[1..^1]

# Converts a string into a camelized string
#camelize : string
create_filter:
  proc camelize(input: string): string =
    result = input.split("_").map(proc(x: string): string = x.toUpper).join("")


# downcase
# string | downcase
# returns string
# Converts a string to all lowercase characters.
create_filter:
  proc downcase(input: string): string =
    result = input.toLower()

# escape
# string | escape
# returns string
# Escapes special characters in HTML, such as <>, ', and &, and converts characters into escape sequences. The filter doesn't effect characters within the string that don’t have a corresponding escape sequence.".
create_filter:
  proc escape(input: string): string =
    result = xmltree.escape(input)

# TODO: This is not working, it will actually escape again
# create_filter:
#   proc escape_once(input: string): string =
#     result = xmltree.escape(input)

# Converts a string into a URL-friendly format
create_filter:
  proc handleize(input: string): string =
    result = input.toLower()
    result = strutils.replace(result, " ", "-")
    result = re.replace(result, re"([^-\w])")



# Removes HTML tags from a string
#strip_html : string

# Strips all leading and trailing whitespace from a string
create_filter:
  proc strip(input: string): string =
    result = input.strip()

# Returns the first characters of a string
#truncate : length:number [ellipsis:string]
create_filter:
  proc truncate(input: string, length: int, ellipsis: string = "..."): string =
    result = input

    if input.len > length:
      result = input[0..length-1] & ellipsis

# Returns the first characters of a string, preserving whole words
#truncatewords : length:number [ellipsis:string]
create_filter:
  proc truncatewords(input: string, length: int, ellipsis: string = "..."): string =
    result = input

    if input.len > length:
      result = input[0..length-1]
      result = result.rsplit(" ", 1)[0] & ellipsis

# Replaces newline characters with HTML line breaks
#newline_to_br : string
create_filter:
  proc newline_to_br(input: string): string =
    result = input.replace("\n", "<br>")

# Converts a string to uppercase
#upcase : string
create_filter:
  proc upcase(input: string): string =
    result = input.toUpper()

# Replaces occurrences of one string with another
#replace : string old:string new:string
create_filter:
  proc replace(input: string, old: string, replacement: string): string =
    result = strutils.replace(input, old, replacement)

# Replaces the first occurrence of one string with another
#replace_first : string old:string new:string
create_filter:
  proc replace_first(input: string, old: string, replacement: string): string =
    result = strutils.split(input, old, 1).join(replacement)

# Splits a string into an array using a delimiter
#split : string delimiter:string
create_filter:
  proc split(input: string, delimiter: string): seq[string] =
    result = input.split(delimiter)

# Removes all whitespace from a string
#strip_newlines : string
create_filter:
  proc strip_newlines(input: string): string =
    result = input.replace("\n", "")


# Removes specified characters from the beginning of a string
#lstrip : string [characters:string]

# Removes specified characters from the end of a string
#rstrip : string [characters:string]

# Reverses the characters in a string
#reverse : string

# Prepends a string to another string
#prepend : string prefix:string

# Escapes a string for use in a URL
#url_encode : string

# Unescapes a URL-encoded string
#url_decode : string

# Escapes a string for use in HTML
#escape : string

# Unescapes a string from HTML
#escape_once : string

# Escapes a string for use in JSON
#json_escape : string

# Returns a slice of a string
#slice : string start:number [length:number]

# Converts newline characters to HTML line breaks
#strip_newlines : string

# Removes all HTML tags from a string
#remove : string substring:string

# Removes the first occurrence of a substring from a string
#remove_first : string substring:string

# Removes the last occurrence of a substring from a string
#remove_last : string substring:string

# Removes leading whitespace from a string
#lstrip : string

# Removes trailing whitespace from a string
#rstrip : string

# Converts a string into an MD5 hash
#md5 : string

# Converts a string into a SHA1 hash
#sha1 : string

# Converts a string into a SHA256 hash
#sha256 : string

# Converts a string into a SHA512 hash
#sha512 : string

# proc apply_string_filter(value: JsonNode, filterName: string, args: JsonNode, context: Context): JsonNode =
#   case filterName
#   of "base64_encode":
#     let encoding = if args.len > 0 and args[0].kind == JString: args[0].getStr else: "standard"
#     let lineLength = if args.len > 1 and args[1].kind == JInt: args[1].getInt else: -1
#     return newJString(encode(value.getStr, encoding, lineLength))
#   # ... other filters ...
#   else:
#     echo "Unknown filter: ", filterName
#     return value
