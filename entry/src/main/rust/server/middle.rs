use axum::{
    extract::{ConnectInfo, Request},
    http::HeaderMap,
    middleware::Next,
    response::Response,
};
use axum_client_ip::ClientIp;
use client_ip::{
    cf_connecting_ip, cloudfront_viewer_address, fly_client_ip, rightmost_x_forwarded_for,
    true_client_ip, x_real_ip,
};
use std::net::{IpAddr, SocketAddr};

// 按优先级尝试从不同代理头提取 IP
fn extract_ip_from_headers(headers: &HeaderMap) -> Option<IpAddr> {
    cf_connecting_ip(headers)
        .or_else(|_| cloudfront_viewer_address(headers))
        .or_else(|_| fly_client_ip(headers))
        .or_else(|_| true_client_ip(headers))
        .or_else(|_| x_real_ip(headers))
        .or_else(|_| rightmost_x_forwarded_for(headers))
        .ok()
}

pub async fn client_ip_middleware(
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    mut request: Request,
    next: Next,
) -> Response {
    let headers = request.headers();
    let ip = extract_ip_from_headers(headers).unwrap_or(addr.ip());

    request.extensions_mut().insert(ClientIp(ip));
    next.run(request).await
}
