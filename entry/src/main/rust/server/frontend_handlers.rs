use axum::response::{Html, IntoResponse, Redirect};

/// Root path redirect to dashboard
pub async fn redirect_to_dashboard() -> impl IntoResponse {
    Redirect::permanent("/dashboard")
}

// 使用 include_str! 宏在编译时包含静态文件
const DASHBOARD_HTML: &str = include_str!("../../assets/html/main.html");

const FAVICON_ICO: &[u8] = include_bytes!("../../assets/icon/favicon.ico");

/// Serve dashboard HTML
pub async fn serve_dashboard() -> impl IntoResponse {
    Html(DASHBOARD_HTML).into_response()
}

pub async fn serve_favicon() -> impl IntoResponse {
    (
        [(
            axum::http::header::CONTENT_TYPE,
            axum::http::HeaderValue::from_static("image/x-icon"),
        )],
        FAVICON_ICO,
    )
}

/// Serve 404 Not Found page
const NOT_FOUND_HTML: &str = include_str!("../../assets/html/404.html");

pub async fn serve_not_found() -> impl IntoResponse {
    Html(NOT_FOUND_HTML).into_response()
}

/// 提供 update.md
const UPDATE_MD: &str = include_str!("../../update.md");

pub async fn serve_update() -> impl IntoResponse {
    ([("content-type", "text/plain")], UPDATE_MD)
}

/// Serve Swagger UI using CDN
const SWAGGER_UI_HTML: &str = include_str!("../../assets/html/swagger_ui.html");

pub async fn serve_swagger_ui() -> impl IntoResponse {
    Html(SWAGGER_UI_HTML).into_response()
}
