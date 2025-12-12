use std::{
    sync::LazyLock,
    sync::atomic::{AtomicBool, AtomicU64, AtomicUsize, Ordering},
    time::{Duration, SystemTime, UNIX_EPOCH},
};

use serde::{Deserialize, Serialize};

/// 全局同步状态管理器
pub struct GlobalSyncStatus {
    /// 是否正在执行 sync_all
    pub is_syncing_all: AtomicBool,
    /// 当前进度 - 已完成数量
    pub current_progress: AtomicUsize,
    /// 总数量
    pub total_packages: AtomicUsize,
    /// 统计信息
    pub total_processed: AtomicUsize,
    pub total_inserted: AtomicUsize,
    pub total_skipped: AtomicUsize,
    pub total_failed: AtomicUsize,
    /// 开始时间 (使用 AtomicU64 存储时间戳)
    pub start_time_nanos: AtomicU64,
    /// 上次同步完成时间 (使用 AtomicU64 存储时间戳)
    pub last_complete_time_nanos: AtomicU64,
}

impl GlobalSyncStatus {
    pub fn new() -> Self {
        Self {
            is_syncing_all: AtomicBool::new(false),
            current_progress: AtomicUsize::new(0),
            total_packages: AtomicUsize::new(0),
            total_processed: AtomicUsize::new(0),
            total_inserted: AtomicUsize::new(0),
            total_skipped: AtomicUsize::new(0),
            total_failed: AtomicUsize::new(0),
            start_time_nanos: AtomicU64::new(0),
            last_complete_time_nanos: AtomicU64::new(0),
        }
    }

    fn set_start_time(&self) {
        let now = SystemTime::now();
        let nanos = now
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos() as u64;
        self.start_time_nanos.store(nanos, Ordering::Relaxed);
    }

    fn set_complete_time(&self) {
        let now = SystemTime::now();
        let nanos = now
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos() as u64;
        self.last_complete_time_nanos
            .store(nanos, Ordering::Relaxed);
    }
}

impl Default for GlobalSyncStatus {
    fn default() -> Self {
        Self::new()
    }
}

/// 全局同步状态
pub static GLOBAL_SYNC_STATUS: LazyLock<GlobalSyncStatus> = LazyLock::new(GlobalSyncStatus::new);

/// 同步状态查询结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatusInfo {
    pub is_syncing_all: bool,
    pub progress: (usize, usize),
    pub total_processed: usize,
    pub total_inserted: usize,
    pub total_skipped: usize,
    pub total_failed: usize,
    pub elapsed_time: Option<Duration>,
    pub estimated_total_time: Option<Duration>,
    pub next_sync_countdown: Option<Duration>,
}

/// 获取当前同步状态
pub fn get_sync_status() -> SyncStatusInfo {
    let status = &*GLOBAL_SYNC_STATUS;

    // 修复：正确计算经过的时间
    let elapsed = {
        let is_syncing = status.is_syncing_all.load(Ordering::Relaxed);
        let start_time_nanos = status.start_time_nanos.load(Ordering::Relaxed);

        if start_time_nanos == 0 {
            None
        } else if is_syncing {
            // 正在同步：计算从开始到现在的时间
            let start_time = SystemTime::UNIX_EPOCH + Duration::from_nanos(start_time_nanos);
            Some(start_time.elapsed().unwrap_or_default())
        } else {
            // 同步已完成：计算从开始到完成的时间
            let complete_time_nanos = status.last_complete_time_nanos.load(Ordering::Relaxed);
            if complete_time_nanos > 0 {
                let start_time = SystemTime::UNIX_EPOCH + Duration::from_nanos(start_time_nanos);
                let complete_time =
                    SystemTime::UNIX_EPOCH + Duration::from_nanos(complete_time_nanos);
                Some(complete_time.duration_since(start_time).unwrap_or_default())
            } else {
                // 有开始时间但没有完成时间，按同步中处理
                let start_time = SystemTime::UNIX_EPOCH + Duration::from_nanos(start_time_nanos);
                Some(start_time.elapsed().unwrap_or_default())
            }
        }
    };

    let current = status.current_progress.load(Ordering::Relaxed);
    let total = status.total_packages.load(Ordering::Relaxed);

    let estimated = match (elapsed, current > 0) {
        (Some(elapsed), true) => {
            let avg_time = elapsed / current as u32;
            Some(avg_time * total as u32)
        }
        _ => None,
    };

    // 计算下次同步倒计时
    let next_sync_countdown = if !status.is_syncing_all.load(Ordering::Relaxed) {
        let last_complete_nanos = status.last_complete_time_nanos.load(Ordering::Relaxed);
        if last_complete_nanos > 0 {
            // 从配置获取同步间隔
            let sync_interval = crate::config::get_config().api_interval();
            let last_complete_time =
                SystemTime::UNIX_EPOCH + Duration::from_nanos(last_complete_nanos);
            let next_sync_time = last_complete_time + Duration::from_secs(sync_interval);

            match next_sync_time.duration_since(SystemTime::now()) {
                Ok(remaining) => Some(remaining),
                Err(_) => Some(Duration::ZERO), // 已经过了下次同步时间
            }
        } else {
            None // 从未同步过
        }
    } else {
        None // 正在同步中
    };

    SyncStatusInfo {
        is_syncing_all: status.is_syncing_all.load(Ordering::Relaxed),
        progress: (current, total),
        total_processed: status.total_processed.load(Ordering::Relaxed),
        total_inserted: status.total_inserted.load(Ordering::Relaxed),
        total_skipped: status.total_skipped.load(Ordering::Relaxed),
        total_failed: status.total_failed.load(Ordering::Relaxed),
        elapsed_time: elapsed,
        estimated_total_time: estimated,
        next_sync_countdown,
    }
}

/// 重置同步状态
pub fn reset_sync_status() {
    let status = &*GLOBAL_SYNC_STATUS;
    status.is_syncing_all.store(false, Ordering::Relaxed);
    status.current_progress.store(0, Ordering::Relaxed);
    status.total_packages.store(0, Ordering::Relaxed);
    status.total_processed.store(0, Ordering::Relaxed);
    status.total_inserted.store(0, Ordering::Relaxed);
    status.total_skipped.store(0, Ordering::Relaxed);
    status.total_failed.store(0, Ordering::Relaxed);
    status.start_time_nanos.store(0, Ordering::Relaxed);
    status.last_complete_time_nanos.store(0, Ordering::Relaxed);
}

/// 开始 sync_all
pub fn start_sync_all(total_packages: usize) {
    let status = &*GLOBAL_SYNC_STATUS;
    status.is_syncing_all.store(true, Ordering::Relaxed);
    status
        .total_packages
        .store(total_packages, Ordering::Relaxed);
    status.current_progress.store(0, Ordering::Relaxed);
    status.total_processed.store(0, Ordering::Relaxed);
    status.total_inserted.store(0, Ordering::Relaxed);
    status.total_skipped.store(0, Ordering::Relaxed);
    status.total_failed.store(0, Ordering::Relaxed);

    // 设置开始时间
    status.set_start_time();
}

/// 更新 sync_all 进度
pub fn update_sync_progress(
    current: usize,
    processed: usize,
    inserted: usize,
    skipped: usize,
    failed: usize,
) {
    let status = &*GLOBAL_SYNC_STATUS;
    status.current_progress.store(current, Ordering::Relaxed);
    status.total_processed.store(processed, Ordering::Relaxed);
    status.total_inserted.store(inserted, Ordering::Relaxed);
    status.total_skipped.store(skipped, Ordering::Relaxed);
    status.total_failed.store(failed, Ordering::Relaxed);
}

/// 结束 sync_all
pub fn end_sync_all() {
    let status = &*GLOBAL_SYNC_STATUS;
    status.is_syncing_all.store(false, Ordering::Relaxed);
    // 记录同步完成时间
    status.set_complete_time();
}
