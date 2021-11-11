mod expression;
mod parser;
mod scanner;
mod util;

fn main() {
    let token: scanner::Token;

    {
        let source = String::from("      print 200;");

        let scan = scanner::Scan::new(source.as_str());

        println!("{:?}", scan.collect::<Vec<scanner::Token>>());
    }

    // println!("{:?}", token);
}
