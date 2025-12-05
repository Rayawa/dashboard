// 数据加载模块
var DashboardDataLoaders = (function () {
    /**
     * 加载应用市场概览统计信息
     * @async
     */
    async function loadOverview() {
        try {
            // 显示加载指示器
            const loadingElements = [
                "loadingOverview",
                "loadingDeveloperCount",
                "loadingAtomicServiceCount",
                "loadingTotalCount",
            ];
            loadingElements.forEach((id) => {
                const el = document.getElementById(id);
                if (el) el.style.display = "inline-block";
            });

            // 获取应用统计
            const appResponse = await fetch(`${API_BASE}/market_info`);
            const market_info = await appResponse.json();
            const app_count = market_info.data.app_count;
            const sync_status = market_info.data.sync_status;

            // 更新统计数据到页面
            document.getElementById("totalCount").textContent = DashboardUtils.formatNumber(
                app_count.total
            );
            document.getElementById("appCount").textContent = DashboardUtils.formatNumber(
                app_count.apps
            );
            document.getElementById("atomicServiceCount").textContent = DashboardUtils.formatNumber(
                app_count.atomic_services
            );
            document.getElementById("developerCount").textContent = DashboardUtils.formatNumber(
                market_info.data.developer_count
            );
            document.getElementById("substance_count").textContent = DashboardUtils.formatNumber(
                market_info.data.substance_count
            );

            // 更新同步状态
            updateSyncStatus(sync_status);

            // 隐藏加载指示器
            loadingElements.forEach((id) => {
                const el = document.getElementById(id);
                if (el) el.style.display = "none";
            });
        } catch (error) {
            console.error("加载概览统计失败:", error);
            // 错误时隐藏加载指示器
            loadingElements.forEach((id) => {
                const el = document.getElementById(id);
                if (el) el.style.display = "none";
            });
        }
    }

    /**
     * 加载应用列表，支持分页、排序、搜索和分类过滤
     * @async
     * @param {number} [page=1] - 页码
     * @param {string} [sortField=currentSort.field] - 排序字段
     * @param {boolean} [sort_desc=currentSort.desc] - 是否降序
     * @param {string} [search=searchTerm] - 搜索关键词
     * @param {string} [category=categoryFilter] - 分类过滤
     */
    async function loadApps(
        page = 1,
        sortField = currentSort.field,
        sort_desc = currentSort.desc,
        search_value = searchTerm,
        search_key = searchKey,
        search_exact = searchExact,
        exclude_huawei = excludeHuawei,
        exclude_atomic = excludeAtomic,
    ) {
        totalPages = 1; // 清空
        DashboardRenderers.renderPagination(); // 清空分页
        try {
            const tableBody = document.getElementById("appTableBody");
            tableBody.innerHTML =
                '<tr><td colspan="12" class="text-center py-12"><div class="inline-block w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-xl animate-spin"></div></td></tr>';

            // 构建API请求URL
            let url = `${API_BASE}/apps/list/${page}?sort=${sortField}&desc=${sort_desc}&page_size=${PAGE_SIZE}`;
            if (search_value) {
                url += `&search_key=${encodeURIComponent(search_key)}&search_value=${encodeURIComponent(search_value)}&search_exact=${search_exact}`;
            }
            if (exclude_huawei) {
                url += `&exclude_huawei=true`;
            }
            if (exclude_atomic) {
                url += `&exclude_atomic=true`;
            }

            const response = await fetch(url);
            const data = await response.json();

            // 更新分页信息
            if (data.data && data.data.total_count) {
                totalPages = Math.ceil(data.data.total_count / PAGE_SIZE);
                currentPage = page;
            }

            let apps = data.data.data || [];

            DashboardRenderers.renderApps(apps.slice(0, PAGE_SIZE)); // 客户端分页（如果需要）
            DashboardRenderers.renderPagination();
        } catch (error) {
            console.error("加载应用列表失败:", error);
            document.getElementById("appTableBody").innerHTML =
                '<tr><td colspan="8" class="text-center py-4 text-gray-500">加载数据失败</td></tr>';
        }
    }

    /**
     * 将Duration对象转换为毫秒数
     * @param {Object} duration - Duration对象，包含secs和nanos字段
     * @returns {number} 毫秒数
     */
    function durationToMs(duration) {
        if (!duration || typeof duration.secs !== 'number' || typeof duration.nanos !== 'number') {
            return 0;
        }
        return duration.secs * 1000 + Math.floor(duration.nanos / 1000000);
    }

    /**
     * 更新同步状态显示
     * @param {Object} syncStatus - 同步状态对象
     */
    function updateSyncStatus(syncStatus) {
        const container = document.getElementById('syncStatusContainer');
        const nextSyncContainer = document.getElementById('nextSyncContainer');
        const status = document.getElementById('syncStatus');
        const progress = document.getElementById('syncProgress');
        const stats = document.getElementById('syncStats');
        const time = document.getElementById('syncTime');
        const nextSyncCountdown = document.getElementById('nextSyncCountdown');

        // 转换Duration格式为毫秒数
        let elapsedTimeMs = syncStatus.elapsed_time ? durationToMs(syncStatus.elapsed_time) : 0;
        let estimatedTotalTimeMs = syncStatus.estimated_total_time ? durationToMs(syncStatus.estimated_total_time) : 0;
        let nextSyncCountdownMs = syncStatus.next_sync_countdown ? durationToMs(syncStatus.next_sync_countdown) : 0;

        if (!syncStatus) {
            container.classList.add('hidden');
            nextSyncContainer.classList.add('hidden');
            return;
        }

        if (syncStatus.is_syncing_all) {
            container.classList.remove('hidden');
            nextSyncContainer.classList.add('hidden');
            status.textContent = '同步中';
            status.className = 'font-medium text-blue-600';

            // 进度
            const [current, total] = syncStatus.progress;
            const percentage = total > 0 ? ((current / total) * 100).toFixed(1) : '0.0';
            progress.textContent = `${current}/${total} (${percentage}%)`;

            // 统计信息
            const statsText = `处理:${syncStatus.total_processed} 新增:${syncStatus.total_inserted} 跳过:${syncStatus.total_skipped} 失败:${syncStatus.total_failed}`;
            stats.textContent = statsText;

            // 时间信息
            if (elapsedTimeMs) {
                const elapsed = formatDuration(elapsedTimeMs);
                time.textContent = `已用时: ${elapsed}`;

                if (estimatedTotalTimeMs) {
                    const estimated = formatDuration(estimatedTotalTimeMs);
                    const remainingMs = estimatedTotalTimeMs - elapsedTimeMs;
                    const remaining = formatDuration(remainingMs);
                    time.textContent += ` 预计剩余: ${remaining}`;
                }
            }
        } else {
            // 检查最近是否有同步完成
            if (syncStatus.total_processed > 0 && syncStatus.progress[1] > 0) {
                container.classList.remove('hidden');
                status.textContent = '同步完成';
                status.className = 'font-medium text-green-600';

                // 同步完成时，只显示统计信息，不显示进度和用时
                progress.textContent = '';
                time.textContent = '';

                const statsText = `处理:${syncStatus.total_processed} 新增:${syncStatus.total_inserted} 跳过:${syncStatus.total_skipped} 失败:${syncStatus.total_failed}`;
                stats.textContent = statsText;

                if (elapsedTimeMs) {
                    const elapsed = formatDuration(elapsedTimeMs);
                    time.textContent = `用时: ${elapsed}`;
                }

                // 显示下次同步倒计时
                updateNextSyncCountdown(nextSyncCountdownMs);
            } else {
                container.classList.add('hidden');
                // 即使没有同步历史，也显示下次同步倒计时（如果有的话）
                if (nextSyncCountdownMs > 0) {
                    updateNextSyncCountdown(nextSyncCountdownMs);
                } else {
                    nextSyncContainer.classList.add('hidden');
                }
            }
        }
    }

    /**
     * 更新下次同步倒计时显示
     * @param {number} countdownMs - 倒计时毫秒数
     */
    function updateNextSyncCountdown(countdownMs) {
        const nextSyncContainer = document.getElementById('nextSyncContainer');
        const nextSyncCountdown = document.getElementById('nextSyncCountdown');

        if (countdownMs === undefined || countdownMs === null) {
            nextSyncContainer.classList.add('hidden');
            return;
        }

        if (countdownMs > 0) {
            nextSyncContainer.classList.remove('hidden');
            const countdownText = formatDuration(countdownMs);
            nextSyncCountdown.textContent = countdownText;
        } else if (countdownMs === 0) {
            nextSyncContainer.classList.remove('hidden');
            nextSyncCountdown.textContent = '即将开始';
            nextSyncCountdown.className = 'font-medium text-red-600 ml-1';
        } else {
            nextSyncContainer.classList.add('hidden');
        }
    }

    /**
     * 格式化持续时间
     * @param {number} milliseconds - 毫秒数
     * @returns {string} 格式化的时间字符串
     */
    function formatDuration(milliseconds) {
        if (milliseconds < 1000) {
            return `${milliseconds}ms`;
        }

        const seconds = Math.floor(milliseconds / 1000);
        if (seconds < 60) {
            return `${seconds}s`;
        }

        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        if (minutes < 60) {
            return `${minutes}m ${remainingSeconds}s`;
        }

        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        return `${hours}h ${remainingMinutes}m`;
    }

    /**
     * 刷新所有数据
     * @async
     */
    async function refreshData() {
        await loadOverview();
        await loadApps();
        DashboardCharts.loadCharts();
        updateLastUpdate();
    }

    return {
        loadOverview: loadOverview,
        loadApps: loadApps,
        refreshData: refreshData,
        updateSyncStatus: updateSyncStatus
    };
})();
