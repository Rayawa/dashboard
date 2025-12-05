//! 工具函数模块，用于处理UTF8编码问题和数据清理

use std::borrow::Cow;

use tracing::Level;

pub fn init_log() {
    // -v -> debug
    // -vv -> trace
    let args: Vec<String> = std::env::args().collect();
    let level = {
        if args.contains(&"-vv".to_string()) {
            Level::TRACE
        } else if args.contains(&"-v".to_string()) {
            Level::DEBUG
        } else if args.contains(&"-d".to_string()) {
            Level::WARN
        } else {
            Level::INFO
        }
    };
    tracing_subscriber::fmt()
        .with_max_level(level)
        .with_ansi(true)
        .init();
}

/// 清理字符串中的无效UTF8字符和空字节
/// 返回一个安全的UTF8字符串
pub fn sanitize_utf8_string(s: &str) -> Cow<'_, str> {
    if s.is_empty() {
        return Cow::Borrowed(s);
    }

    // 检查是否包含需要清理的字符
    if s.contains('\0')
        || s.chars()
            .any(|c| c.is_control() && c != '\n' && c != '\r' && c != '\t')
    {
        // 清理字符串：移除空字节和替换控制字符
        let cleaned: String = s
            .chars()
            .filter(|&c| c != '\0') // 移除空字节
            .map(|c| {
                if c.is_control() && c != '\n' && c != '\r' && c != '\t' {
                    ' ' // 替换控制字符为空格（除了常见的空白字符）
                } else {
                    c
                }
            })
            .collect();

        Cow::Owned(cleaned)
    } else {
        Cow::Borrowed(s)
    }
}

/// 清理字符串中的空字节
pub fn remove_null_bytes(s: &str) -> Cow<'_, str> {
    if s.contains('\0') {
        Cow::Owned(s.replace('\0', ""))
    } else {
        Cow::Borrowed(s)
    }
}

/// 清理字符串，确保它是有效的UTF8
/// 这个方法更激进，会移除所有控制字符和空字节
pub fn ensure_valid_utf8(s: &str) -> String {
    s.chars()
        .filter(|&c| c != '\0') // 移除空字节
        .filter(|c| !c.is_control() || *c == '\n' || *c == '\r' || *c == '\t') // 保留常见空白字符
        .collect()
}

/// 检查字符串是否包含无效的UTF8字符
pub fn has_invalid_utf8_chars(s: &str) -> bool {
    s.contains('\0')
        || s.chars()
            .any(|c| c.is_control() && c != '\n' && c != '\r' && c != '\t')
}

#[cfg(test)]
mod tests {
    use crate::utils::{
        ensure_valid_utf8, has_invalid_utf8_chars, remove_null_bytes, sanitize_utf8_string,
    };

    #[test]
    fn test_sanitize_utf8_string() {
        // 测试空字符串
        assert_eq!(sanitize_utf8_string(""), "");

        // 测试正常字符串
        assert_eq!(sanitize_utf8_string("正常文本"), "正常文本");

        // 测试包含空字节的字符串
        let input = "正常文本\0中间有空字节\0结尾";
        let expected = "正常文本中间有空字节结尾";
        assert_eq!(sanitize_utf8_string(input), expected);

        // 测试控制字符
        let input = "文本\x01控制字符\x02测试";
        let expected = "文本 控制字符 测试";
        assert_eq!(sanitize_utf8_string(input), expected);
    }

    #[test]
    fn test_remove_null_bytes() {
        assert_eq!(remove_null_bytes(""), "");
        assert_eq!(remove_null_bytes("正常文本"), "正常文本");
        assert_eq!(remove_null_bytes("文本\0有空字节"), "文本有空字节");
        assert_eq!(remove_null_bytes("\0开头\0中间\0结尾\0"), "开头中间结尾");
    }

    #[test]
    fn test_ensure_valid_utf8() {
        assert_eq!(ensure_valid_utf8(""), "");
        assert_eq!(ensure_valid_utf8("正常文本"), "正常文本");
        assert_eq!(ensure_valid_utf8("文本\0\x01测试"), "文本测试");
    }

    #[test]
    fn test_has_invalid_utf8_chars() {
        assert!(!has_invalid_utf8_chars(""));
        assert!(!has_invalid_utf8_chars("正常文本"));
        assert!(has_invalid_utf8_chars("文本\0"));
        assert!(has_invalid_utf8_chars("文本\x01"));
    }
}
