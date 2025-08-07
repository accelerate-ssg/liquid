import std/macros, std/strutils

macro with*(instance: typed, userBody: untyped): untyped =
  ## A simpler macro to bring fields of an object instance into the current scope
  ## by creating template definitions for each field access.
  
  result = newStmtList()
  
  let instanceTypeNode = getType(instance)
  var objectTypeNode: NimNode
  
  # Handle different type representations
  if instanceTypeNode.kind == nnkRefTy and instanceTypeNode[0].kind == nnkObjectTy:
    objectTypeNode = instanceTypeNode[0]
  elif instanceTypeNode.kind == nnkObjectTy:
    objectTypeNode = instanceTypeNode  
  elif instanceTypeNode.kind == nnkBracketExpr and instanceTypeNode[0].eqIdent("ref"):
    objectTypeNode = instanceTypeNode[1]
  else:
    error("with macro expects an object or a ref to an object. Got: " & repr(instanceTypeNode), instance)
    return
  
  # Get the actual object definition
  var typeDefNode = getImpl(objectTypeNode)
  
  if typeDefNode.kind == nnkTypeDef and typeDefNode.len >= 3:
    typeDefNode = typeDefNode[2]
    if typeDefNode.kind == nnkRefTy and typeDefNode.len > 0:
      typeDefNode = typeDefNode[0]
  
  # Create templates for each field
  if typeDefNode.kind == nnkObjectTy:
    for child in typeDefNode:
      if child.kind == nnkRecList:
        for fieldDef in child:
          if fieldDef.kind == nnkIdentDefs and fieldDef.len >= 3:
            for i in 0 ..< (fieldDef.len - 2):
              var fieldName = fieldDef[i]
              # Handle exported fields
              if fieldName.kind == nnkPostfix and fieldName.len >= 2:
                fieldName = fieldName[1]
              
              if fieldName.kind == nnkIdent:
                # Create a template for this field that accesses it from the instance
                let fieldTemplate = quote do:
                  template `fieldName`: untyped = `instance`.`fieldName`
                result.add(fieldTemplate)
  
  # Add the user body
  result.add(userBody)