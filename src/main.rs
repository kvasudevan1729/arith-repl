use std::io::{self, BufRead, Write};

use lrlex::lrlex_mod;
use lrpar::lrpar_mod;

lrlex_mod!("calc.l");
lrpar_mod!("calc.y");

fn main() {
    let lexerdef = calc_l::lexerdef();
    let stdin = io::stdin();
    loop {
        print!(">>>");
        io::stdout().flush().ok();
        match stdin.lock().lines().next() {
            Some(Ok(ref l)) => {
                if l.trim().is_empty() {
                    continue;
                }
                let lexer = lexerdef.lexer(l);
                let (res, errs) = calc_y::parse(&lexer);
                for e in errs {
                    println!("err: {}", e.pp(&lexer, &calc_y::token_epp));
                }
                match res {
                    Some(r) => match r {
                        Ok(v) => {
                            println!(
                                "Result:\n id: {}, val: {}",
                                v.get_expr_id(),
                                v.get_expr_val()
                            );
                            println!("\n span: {}", v.get_span());
                        }
                        Err(e) => {
                            eprintln!("Error:\n{}", e)
                        }
                    },
                    _ => eprintln!("Unable to evaluate expression!"),
                }
            }
            _ => break,
        }
    }
}
