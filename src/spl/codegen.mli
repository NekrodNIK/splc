type error = GetTargetError of string | WriteToFileError of string

val emit :
  ast:string Syntax.t Located.t ->
  module_name:string ->
  output_path:string ->
  (unit, error) result
