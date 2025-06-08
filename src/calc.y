%start Stmt
%avoid_insert "INT"
%%

Stmt -> Result<ExprAssign, ParseError>:
     'ID' '=' Expr { 
	let var_id = $1.map_err(|e| ParseError::new(&e.to_string()))?;
	let var_id_str = $lexer.span_str(var_id.span());
	let s = show_result($3)?;
	Ok(ExprAssign::new(var_id_str.to_string(), s, $span))
     }
    ;
Expr -> Result<Nums, ParseError>:
      Expr '+' Term {
          let v = do_arith_calc($1?, $3?, ArithOp::Add);
	  Ok(v)
      }
    | Expr '-' Term {
	  let v = do_arith_calc($1?, $3?, ArithOp::Sub);
	  Ok(v)
      }
    | Term { $1 }
    ;

Term -> Result<Nums, ParseError>:
      Term '*' DivTerm {
	  let v = do_arith_calc($1?, $3?, ArithOp::Multi);
	  Ok(v)
      }
    | DivTerm { $1 }
    ;

DivTerm -> Result<Nums, ParseError>:
    DivTerm '/' Factor { 
        let dividend = $1?;
        let divisor = $3?;
	match divisor {
	    Nums::U64(v) => {
		if v == 0 {
		    return Err(ParseError::new("Divisor can't be zero!"));
		}
	    }
	    Nums::F64(v) => {
		if v == 0.0 {
		    return Err(ParseError::new("Divisor can't be zero!"));
		}
	    }
	}
	let v = do_arith_calc(dividend, divisor, ArithOp::Div);
	Ok(v)
    }
    | Factor { $1 }
    ;

Factor -> Result<Nums, ParseError>:
      '(' Expr ')' { $2 }
    | 'INT'
      {
          let v = $1.map_err(|e| ParseError::new(&e.to_string()))?;
          parse_int($lexer.span_str(v.span()))
      }
    | 'FLOAT'
      {
          let v = $1.map_err(|e| ParseError::new(&e.to_string()))?;
          parse_float($lexer.span_str(v.span()))
      }
    ;
%%
use std::error::Error;
use std::fmt;

use cfgrammar::Span;

pub(crate) struct ExprAssign {
   id: String,
   expr_val: String,
   span: Span
}

impl ExprAssign {
    fn new(id: String, s: String, span: Span) -> Self {
        Self {id: id, expr_val: s, span: span}
    }

    pub(crate) fn get_expr_id(&self) -> &str {
	self.id.as_str()
    }

    pub(crate) fn get_span(&self) -> usize {
	self.span.len()
    }

    pub(crate) fn get_expr_val(&self) -> &str {
	self.expr_val.as_str()
    }
}

fn show_result(expr_val: Result<Nums, ParseError>) -> Result<String, ParseError> {
    let val = expr_val?;
    match val {
        Nums::U64(u) => Ok(format!("Value: {}", u)),
        Nums::F64(u) => Ok(format!("Value: {}", u)),
    }
}

enum Nums {
    U64(u64),
    F64(f64),
}

fn parse_int(s: &str) -> Result<Nums, ParseError> {
    match s.parse::<u64>() {
        Ok(val) => Ok(Nums::U64(val)),
        Err(_) => {
            eprintln!("{} - can't be represented as a u64", s);
            Err(ParseError::new("Invalid token!"))
        }
    }
}

fn parse_float(s: &str) -> Result<Nums, ParseError> {
    match s.parse::<f64>() {
        Ok(val) => Ok(Nums::F64(val)),
        Err(_) => {
            eprintln!("{} - can't be represented as a f64", s);
            Err(ParseError::new("Invalid token!"))
        }
    }
}

#[derive(Debug)]
pub(crate) struct ParseError {
    msg: String,
}

impl ParseError {
    fn new(s: &str) -> Self {
        Self { msg: s.to_string() }
    }
}
impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "parse error: {}", self.msg)
    }
}

impl Error for ParseError {}

enum ArithOp {
    Add,
    Sub,
    Multi,
    Div,
}

fn do_arith_calc(lhs: Nums, rhs: Nums, op: ArithOp) -> Nums {
    match lhs {
        Nums::U64(l) => match rhs {
            Nums::U64(r) => match op {
                ArithOp::Add => Nums::U64(l + r),
                ArithOp::Sub => Nums::U64(l - r),
                ArithOp::Multi => Nums::U64(l * r),
                ArithOp::Div => Nums::U64(l / r),
            },
            Nums::F64(r) => match op {
                ArithOp::Add => Nums::F64((l as f64) + r),
                ArithOp::Sub => Nums::F64((l as f64) - r),
                ArithOp::Multi => Nums::F64((l as f64) * r),
                ArithOp::Div => Nums::F64((l as f64) / r),
            },
        },
        Nums::F64(l) => match rhs {
            Nums::F64(r) => match op {
                ArithOp::Add => Nums::F64(l + r),
                ArithOp::Sub => Nums::F64(l - r),
                ArithOp::Multi => Nums::F64(l * r),
                ArithOp::Div => Nums::F64(l / r),
            },
            Nums::U64(r) => match op {
                ArithOp::Add => Nums::F64(l + (r as f64)),
                ArithOp::Sub => Nums::F64(l - (r as f64)),
                ArithOp::Multi => Nums::F64(l * (r as f64)),
                ArithOp::Div => Nums::F64(l / (r as f64)),
            },
        },
    }
}
