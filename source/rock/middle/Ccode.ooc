import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp, FunctionCall, Cast, Block, Match,
       Comparison, IntLiteral, If, Else, Dereference
import tinker/[Trail, Resolver, Response, Errors]

//Ccode: class extends Conditional {
Ccode: class extends ControlStatement {
    init: func (token: Token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        copy
    }
/*
    getCatches: func -> List<Case> { catches }

    addCatch: func (caze: Case) {
        catches add(caze)
    }
*/
    accept: func (visitor: Visitor) {
        println("accepting c code")
        visitor visitCcode(this)

    }
/*
    replace: func (oldie, kiddo: Node) -> Bool {
        false
    }
*/
    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)
        response := body resolve(trail, res)
        trail pop(this)
        return response
        //return Response OK
    }

    toString: func -> String { class name }

}
