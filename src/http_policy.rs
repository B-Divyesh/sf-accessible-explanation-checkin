use axum::{
    http::{header, HeaderValue},
    response::Response,
};

/// Applies cache policy after routing so bearer-link navigation cannot be kept
/// in a shared browser or intermediary cache, while build assets stay cheap to
/// reload. `build_sha` is also a stable validator for an immutable deployment.
pub fn apply_response_policy(mut response: Response, path: &str, build_sha: &str) -> Response {
    let headers = response.headers_mut();
    if path.starts_with("/api/")
        || path.starts_with("/c/")
        || path.starts_with("/review/")
        || path.starts_with("/receipt/")
    {
        headers.insert(
            header::CACHE_CONTROL,
            HeaderValue::from_static("private, no-store"),
        );
        headers.remove(header::ETAG);
    } else if path.starts_with("/assets/") {
        headers.insert(
            header::CACHE_CONTROL,
            HeaderValue::from_static("public, max-age=31536000, immutable"),
        );
        set_etag(headers, build_sha);
    } else {
        // HTML, the service worker and the manifest must be refreshed whenever
        // a deployment changes so they can point at the current asset set.
        headers.insert(
            header::CACHE_CONTROL,
            HeaderValue::from_static("no-cache, max-age=0, must-revalidate"),
        );
        set_etag(headers, build_sha);
    }
    response
}

fn set_etag(headers: &mut axum::http::HeaderMap, build_sha: &str) {
    let safe_sha = build_sha
        .chars()
        .filter(|character| {
            character.is_ascii_alphanumeric() || *character == '-' || *character == '_'
        })
        .collect::<String>();
    let value = format!(
        "W/\"{}\"",
        if safe_sha.is_empty() {
            "development"
        } else {
            &safe_sha
        }
    );
    if let Ok(value) = HeaderValue::from_str(&value) {
        headers.insert(header::ETAG, value);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::response::IntoResponse;

    #[test]
    fn bearer_navigation_and_api_are_never_stored() {
        for path in [
            "/api/checkins/a-private-token",
            "/c/a-private-token",
            "/review/a-private-token",
            "/receipt/a-private-token",
        ] {
            let response = apply_response_policy("ok".into_response(), path, "sha");
            assert_eq!(
                response.headers()[header::CACHE_CONTROL],
                "private, no-store",
                "{path}"
            );
            assert!(response.headers().get(header::ETAG).is_none());
        }
    }

    #[test]
    fn assets_are_immutable_and_shell_is_revalidated() {
        let asset = apply_response_policy("ok".into_response(), "/assets/app-123.js", "abc123");
        assert_eq!(
            asset.headers()[header::CACHE_CONTROL],
            "public, max-age=31536000, immutable"
        );
        assert_eq!(asset.headers()[header::ETAG], "W/\"abc123\"");

        let shell = apply_response_policy("ok".into_response(), "/sw.js", "abc123");
        assert_eq!(
            shell.headers()[header::CACHE_CONTROL],
            "no-cache, max-age=0, must-revalidate"
        );
        assert_eq!(shell.headers()[header::ETAG], "W/\"abc123\"");
    }
}
