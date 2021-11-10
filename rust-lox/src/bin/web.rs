#[macro_use]
extern crate rocket;

use rocket::form::Form;
use rust_lox::scanner;

#[derive(FromForm)]
struct Source<'a> {
  source: &'a str,
}

#[post("/", data = "<form>")]
fn index<'a>(form: Form<Source>) -> String {
  let source = form.into_inner().source;
  let tokens: Vec<scanner::Token> = scanner::Scan::new(source).collect();

  serde_json::to_string(&tokens).unwrap_or(String::from(r#"{error: "can't lex this"}"#))
}

#[launch]
fn rocket() -> _ {
  rocket::build().mount("/", routes![index])
}
