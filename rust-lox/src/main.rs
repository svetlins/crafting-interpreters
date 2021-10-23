mod scanner;

fn main() {
    let source = "      print 200;";

    let mut scan = scanner::Scan::new(source);

    scan.scan_token();

    scan.print();
}
