type ('id) expr =
  | OpExpr of ('id) expr * ('id) expr
  | VarExpr of 'id
  | NumLitExpr of int

type ('id) decl =
  | ValDecl of 'id * ('id) expr
  | VarDecl of 'id * ('id) expr

type ('id) stmt = 
  | ExprStmt of ('id) expr
  | ReturnStmt of ('id) expr
  | DeclStmt of ('id) decl
  | AssignStmt of 'id * ('id) expr

type ('id) ast = ('id) stmt Seq.node


