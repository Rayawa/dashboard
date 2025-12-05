use serde::{Deserialize, Serialize};
use std::fmt::Display;
use utoipa::ToSchema;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord, ToSchema)]
pub enum AppQuery {
    #[serde(rename = "pkg_name")]
    PkgName(String),
    #[serde(rename = "app_id")]
    AppId(String),
}

impl AppQuery {
    pub fn pkg_name(pkg_name: impl ToString) -> Self {
        Self::PkgName(pkg_name.to_string())
    }

    pub fn app_id(app_id: impl ToString) -> Self {
        Self::AppId(app_id.to_string())
    }

    pub fn app_info_type(&self) -> &str {
        match self {
            AppQuery::PkgName(_) => "pkgName",
            AppQuery::AppId(_) => "appId",
        }
    }

    pub fn app_db_name(&self) -> &str {
        match self {
            AppQuery::PkgName(_) => "pkg_name",
            AppQuery::AppId(_) => "app_id",
        }
    }

    pub fn page_detail_fmt(&self) -> String {
        match self {
            AppQuery::PkgName(_) => unreachable!("不能吧, 不能用 pkg_name 请求 page-detail 吧"),
            AppQuery::AppId(app_id) => format!("webAgAppDetail|{}", app_id),
        }
    }

    pub fn name(&self) -> &str {
        match self {
            AppQuery::PkgName(pkg_name) => pkg_name,
            AppQuery::AppId(app_id) => app_id,
        }
    }
}

impl Display for AppQuery {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AppQuery::PkgName(pkg_name) => write!(f, "pkg_name={}", pkg_name),
            AppQuery::AppId(app_id) => write!(f, "app_id={}", app_id),
        }
    }
}
