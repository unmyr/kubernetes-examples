use actix_web::{get, web, App, HttpServer, Responder, HttpResponse};
use serde_json::json;
use std::env;

#[get("/hello/{name}")]
async fn greet(name: web::Path<String>) -> impl Responder {
    HttpResponse::Ok().json(json!({"message": format!("Hello {name}!")}))
}

#[actix_web::main] // or #[tokio::main]
async fn main() -> std::io::Result<()> {
    let mut args: Vec<String> = env::args().collect();
    args.remove(0);

    let host = match args.pop() {
        Some(val) => val,
        None => String::from("127.0.0.1"),
    };
    println!("server is listening on {host}:8080 port");

    HttpServer::new(|| {
        App::new().service(greet)
    })
    .bind((host, 8080))?
    .run()
    .await
}
