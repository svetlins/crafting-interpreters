mod compiler;

use compiler::scanner;

fn main() {
    let source = "      print 200;";

    let mut scan = scanner::Scan::new(source);

    scan.scan_token();

    let mut c = source.chars().peekable();

    let n = c.next();
    let p = c.peek();
}
