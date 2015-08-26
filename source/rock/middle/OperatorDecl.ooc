import ../frontend/Token
import FunctionDecl, Expression, Type, Visitor, Node, Argument, TypeDecl
import tinker/[Resolver, Response, Trail, Errors]

OperatorDecl: class extends Expression {

		symbol: String {
				get { symbol }
				set (s) {
						if (s == "implicit as") {
								symbol = "as"
								implicit = true
						} else {
								symbol = s
						}
				}
		}

		implicit := false // for implicit as
		_doneImplicit := false

		fDecl : FunctionDecl { get set }

		init: func ~opDecl (=symbol, .token) {
				init(token)
		}

		init: func ~noSymbol (.token) {
				super(token)
				setFunctionDecl(FunctionDecl new("", token))
		}

		clone: func -> This {
				copy := new(symbol, token)
				copy fDecl = fDecl clone()
				copy
		}

		setFunctionDecl: func (=fDecl) {
				fDecl setInline(true)
				fDecl oDecl = this
		}
		getFunctionDecl: func -> FunctionDecl { fDecl }

		getSymbol: func -> String { symbol }

		accept: func (visitor: Visitor) { visitor visitFunctionDecl(fDecl) }

		getType: func -> Type { fDecl getType() }

		toString: func -> String {
				"operator " + symbol + " " + (fDecl ? fDecl getArgsRepr() : "")
		}

		isResolved: func -> Bool { false }

		setByRef: func (byref: Bool) {
				fDecl isThisRef = byref
		}

		setAbstract: func (abs: Bool) {
				fDecl setAbstract(abs)
		}

		computeName: func {
				assert(fDecl != null)

				sb := Buffer new()
				sb append("__OP_"). append(getName())

				for(arg in fDecl args) {
						sb append("_"). append(arg instanceOf?(VarArg) ? "__VA_ARG__" : arg getType() toMangledString())
				}

				if(!fDecl isVoid()) {
						sb append("__"). append(fDecl getReturnType() toMangledString())
				}

				fDecl setName(sb toString())
		}

		resolve: func (trail: Trail, res: Resolver) -> Response {
				fDecl resolve(trail, res)

				response := checkNumArgs(res)
				if (!response ok()) return response

				reponse := checkImplicitConversions(res)
				if (!response ok()) return response

				Response OK
		}

		checkNumArgs: func (res: Resolver) -> Response {
				numArgs := fDecl args size
				if (fDecl owner) {
						numArgs += 1
				}

				match symbol {
						// unary only
						case "as" =>
								if (numArgs != 1) {
										return needArgs(res, "exactly 1", numArgs)
								}

						// unary or binary
						case "-" || "+" =>
								/*if (numArgs < 1 || numArgs > 2) {
										return needArgs(res, "1 or 2", numArgs)
								}*/

						// only case of 3-arguments only
						case "[]=" =>
								if (numArgs != 3) {
										//return needArgs(res, "exactly 3", numArgs)
								}
						// cogenco special
						case "[]" =>

						case "+=" =>
						case "-=" =>
						case "+" =>
						case "-" =>
						case "*" =>
						case "*=" =>
						case "/=" =>
						//case "" =>

						// all remaining operators are binary
						case =>
								if (numArgs != 2) {
										return needArgs(res, "exactly 2", numArgs)
								}
				}

				Response OK
		}

		checkImplicitConversions: func (res: Resolver) -> Response {
				if (!implicit) return Response OK
				if (_doneImplicit) return Response OK

				fromType := fDecl args get(0) getType()
				toType := fDecl getReturnType()

				if(fromType == null || !fromType isResolved()) {
						res wholeAgain(this, "need first arg's type")
						return Response OK
				}

				match (fromType getRef()) {
						case td: TypeDecl =>
								td implicitConversions add(this)
								_doneImplicit = true
				}

				Response OK
		}

		needArgs: func (res: Resolver, expected: String, given: Int) -> Response {
				message := "Overloading of '#{symbol}' requires #{expected} argument(s), not #{given}."
				err := InvalidOperatorOverload new(token, message)
				res throwError(err)

				Response LOOP
		}

		getName: func -> String {
				return match (symbol) {
						case "[]"  =>  "IDX"
						case "+"   =>  "ADD"
						case "-"   =>  "SUB"
						case "*"   =>  "MUL"
						case "**"  =>  "EXP"
						case "/"   =>  "DIV"
						case "<<"  =>  "B_LSHIFT"
						case ">>"  =>  "B_RSHIFT"
						case "^"   =>  "B_XOR"
						case "&"   =>  "B_AND"
						case "|"   =>  "B_OR"

						case "[]=" =>  "IDX_ASS"
						case "+="  =>  "ADD_ASS"
						case "-="  =>  "SUB_ASS"
						case "*="  =>  "MUL_ASS"
						case "**=" =>  "EXP_ASS"
						case "/="  =>  "DIV_ASS"
						case "<<=" =>  "B_LSHIFT_ASS"
						case ">>=" =>  "B_RSHIFT_ASS"
						case "^="  =>  "B_XOR_ASS"
						case "&="  =>  "B_AND_ASS"
						case "|="  =>  "B_OR_ASS"

						case "=>"  =>  "DOUBLE_ARR"
						case "&&"  =>  "L_AND"
						case "||"  =>  "L_OR"
						case "%"   =>  "MOD"
						case "="   =>  "ASS"
						case "=="  =>  "EQ"
						case "<="  =>  "GTE"
						case ">="  =>  "LTE"
						case "!="  =>  "NE"
						case "!"   =>  "NOT"
						case "<"   =>  "LT"
						case ">"   =>  "GT"
						case "<=>" =>  "CMP"
						case "~"   =>  "B_NEG"
						case "as"  =>  "AS"

						case "??"  => "NULL_COAL"

						case       =>  token module params errorHandler onError(InvalidOperatorOverload new(token, "Unknown overloaded symbol: %s" format(symbol))); "UNKNOWN"
				}
		}

		replace: func (oldie, kiddo: Node) -> Bool { false }

		isScope: func -> Bool { true }

}

InvalidOperatorOverload: class extends Error {
		init: super func ~tokenMessage
}


OverloadStatus: enum {
		TRYAGAIN // operator usage waiting for something else to resolve
		REPLACED // operator usage was replaced with a call to an overload
		NONE     // operator usage fully resolved, no overload in sight
}
