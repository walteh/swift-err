@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

@attached(body)
public macro err_traced() = #externalMacro(module: "ErrMacros", type: "ErrTraced")
