// 应用详情模块
var DashboardAppDetails = (function () {
    /**
     *
     * @param {string} code
     * @returns {string}
     */
    function parse_device_code(code) {
        switch (code) {
            case '0':
                return '手机';
            case '3':
                return '智慧屏';
            case '4':
                return '平板';
            case '7':
                return '智能手表';
            case '9':
                return '运动手表';
            case '15':
                return '电脑';
            default:
                return `未知 ${code}`;
        }
    }

    /**
     * 在模态框中显示应用详细信息
     * @async
     * @param {string} appId - 应用ID
     */
    async function showAppDetail(appId) {
        try {
            // 更新当前应用信息
            currentApp.appId = appId;

            // 更新URL参数
            window.updateUrlParam('app_id', appId);

            const modal = document.getElementById("appDetailModal");
            const modalContent = document.getElementById("appDetailContent");
            modalContent.innerHTML =
                '<div class="flex justify-center items-center py-8"><div class="w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-xl animate-spin"></div></div>';

            const response = await fetch(`${API_BASE}/apps/app_id/${appId}`);
            const data = await response.json();
            const app = data.data.full_info;
            const getDataSuccess = data.data.get_data !== false; // 明确判断是否为 false

            if (!data.success) {
                const error = data.data.error;
                let html = `
                    <div class="text-center py-8">
                        <div class="text-red-500 text-lg font-medium mb-2">获取数据失败，应用可能已经下架/不存在</div>
                        <div class="text-gray-600 text-sm">${error || '未知错误'}</div>
                    </div>
                `;
                modalContent.innerHTML = html;
                modal.classList.remove("hidden");
                return;
            }

            // 更新当前应用包名信息
            currentApp.pkgName = app.pkg_name;

            // 如果是通过包名打开的，更新URL参数
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('pkg_name') && !urlParams.has('app_id')) {
                window.updateUrlParam('app_id', app.app_id);
            }
            let device_codes = app.main_device_codes || [];
            const same_css = `class="inline-flex items-center px-3 py-1 rounded-xl text-sm font-medium`;
            let device_html = '';
            device_codes.forEach(code => {
                device_html += `
                <span ${same_css} bg-emerald-100 text-emerald-800">
                        ${parse_device_code(code)}
                    </span>`;
            });

            const text_class = `<p class="w-full px-2 py-1 text-gray-500 text-sm">`;
            const label_class = `<p class="w-full md:w-1/2 px-2 py-1"><strong>`;
            let record_html = "";
            if (app.app_recordal_info) {
                record_html = `${label_class}备案信息: ${app.app_recordal_info}</br>${app.recordal_entity_title} ${app.recordal_entity_name}</strong></p>`
            }
            let comment_label = app.comment ? `${text_class}此应用由` : ""
            if (app.comment) {
                const comment = app.comment;
                const parts = [];
                if (comment.platform) parts.push(`${comment.platform} 的`);
                if (comment.user) parts.push(`${comment.user} 提交`);
                if (comment.note) parts.push(`备注: ${comment.note}`);
                comment_label += parts.join(' ');
            }

            let html = `
              ${!getDataSuccess ? `
                  <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
                      <strong class="font-bold">注意!</strong>
                      <span class="block sm:inline">无法从 AppGallery 获取到最新的数据, 可能应用已经下架</span>
                  </div>
              ` : ''}
                <div class="flex flex-col md:flex-row gap-2">
                    <div class="md:w-1/6 text-center md:text-center">
                        <img src="${app.icon_url || "/img/default-app-icon.png"}" class="w-24 h-24 app-icon mx-auto item-center" alt="${app.name}">
                        <p class="mb-1 text-lg">${DashboardUtils.renderStars(app.average_rating) || "无评分"}</p>
                        <p class="text-gray-500 mb-2">${app.total_star_rating_count || "无"} 评分</p>
                        <div class="flex flex-col gap-2">
                            <a href="https://appgallery.huawei.com/app/detail?id=${app.pkg_name}" target="_blank" class="btn-animation mt-4 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-xl hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-300 transform hover:scale-105">
                                在华为应用市场查看
                            </a>
                            <button onclick="window.copyToClipboard(window.location, this)" class="btn-animation px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-xl hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-300 transform hover:scale-105">
                                复制当前页面链接
                            </button>
                            <button onclick="window.shareLink('分享应用: ${app.name}', '查看应用详情: ${app.name}', window.location)" class="btn-animation px-4 py-2 bg-purple-600 text-white text-sm font-medium rounded-xl hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-300 transform hover:scale-105">
                                分享当前页面
                            </button>
                        </div>
                    </div>
                    <div class="md:w-5/6">
                        <h4 class="text-2xl font-bold text-gray-900 mb-2">${app.name || "未知应用"}</h4>
                        <p class="text-gray-600 mb-4">${app.developer_name || "未知开发者"}</p>
                        <div class="flex flex-wrap gap-2 mb-4">
                            <span ${same_css} bg-blue-100 text-blue-800">${app.kind_type_name || "未知"}-${app.kind_name || "未知"}-${app.tag_name}</span>
                            <span ${same_css} bg-purple-100 text-purple-800">${app.version} (${app.version_code})</span>
                            <span ${same_css} bg-cyan-100 text-cyan-800">目标 api 版本 ${DashboardUtils.parse_sdk_version(app.target_sdk)}</span>
                            <span ${same_css} bg-emerald-100 text-emerald-800">最小 api 版本 ${DashboardUtils.parse_sdk_version(app.minsdk)}</span>
                            <span ${same_css} bg-amber-100 text-amber-800">编译 api 版本 ${app.compile_sdk_version}</span>
                        </div>
                        <div class="flex flex-wrap -mx-2 mb-2">
                            ${label_class}评分数据更新时间:</strong> <span>${DashboardUtils.formatDate(app.created_at)}</span></p>
                            ${label_class}应用数据更新时间:</strong> <span>${DashboardUtils.formatDate(app.created_at)}</span></p>
                            ${label_class}应用爬取时间:</strong> <span>${DashboardUtils.formatDate(app.created_at)}</span></p>
                            ${label_class}应用上架时间(可能):</strong> <span>${new Date(app.listed_at).toLocaleDateString("zh-CN")}</span></p>
                            ${label_class}应用更新时间:</strong> <span>${DashboardUtils.formatDate(app.release_date)}</span></p>
                            ${label_class}下载量:</strong> <span>${DashboardUtils.formatNumber(app.download_count || 0)}</span></p>
                            ${label_class}应用大小:</strong> <span>${DashboardUtils.formatSize(app.size_bytes || 0)}</span></p>
                            ${label_class}App ID:</strong> <span>${app.app_id}</span></p>
                            ${label_class}Package Name:</strong> <span>${app.pkg_name}</span></p>
                            ${label_class}开发者名称:</strong> <span>${app.developer_name}</span></p>
                            ${label_class}开发者英文名:</strong> <span>${app.dev_en_name}</span></p>
                            <br>
                            <p class="w-full px-2 py-1"><strong>上架终端列表</strong></p>
                            <div class="w-full px-2 py-1 flex flex-wrap gap-2">${device_html}</div>
                            ${text_class}应用上架终端类型与APP Gallery同步，不代表实际情况</p>
                            ${record_html}
                            ${comment_label}
                        </div>
                        <hr class="my-4 border-gray-200">
                        <div id="descriptionContainer"></div>
                    </div>
                </div>
                <div class="mt-6">
                    <h5 class="text-lg font-semibold text-gray-900 mb-3">下载量变化趋势</h5>
                    <div class="chart-container" style="height: 300px;">
                        <canvas id="downloadHistoryChart"></canvas>
                    </div>
                    <div id="noHistoryMessage" class="text-center py-4 text-gray-500 hidden">暂无历史下载数据</div>
                </div>
                <div class="mt-6">
                    <h5 class="text-lg font-semibold text-gray-900 mb-3">下载量增量趋势</h5>
                    <div class="chart-container" style="height: 300px;">
                        <canvas id="downloadIncrementChart"></canvas>
                    </div>
                    <div id="noIncrementMessage" class="text-center py-4 text-gray-500 hidden">暂无历史下载数据</div>
                </div>
            `;

            modalContent.innerHTML = html;

            // 处理描述文本展开/收起
            const plainDesc = app.description || "无描述";
            const description = plainDesc.replace(/\n/g, "<br>");
            const descContainer = document.getElementById("descriptionContainer");
            const MAX_LENGTH = 200;
            const MAX_LINES = 7;
            let isExpanded = false;

            // 计算行数
            const lineCount = plainDesc.split('\n').length;

            if (plainDesc.length > MAX_LENGTH || lineCount > MAX_LINES) {
                let truncated = "";
                // 如果行数超过限制，按行数截断
                if (lineCount > MAX_LINES) {
                    const lines = plainDesc.split('\n');
                    truncated = lines.slice(0, MAX_LINES).join('\n') + "...";
                } else {
                    // 否则按字符数截断
                    truncated = plainDesc.substring(0, MAX_LENGTH) + "...";
                }
                const truncatedHtml = truncated.replace(/\n/g, "<br>");
                descContainer.innerHTML = `
                    <p id="descriptionText" class="text-gray-700">${truncatedHtml}</p>
                    <button id="toggleDescription" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 text-sm font-medium mt-2">展开更多</button>
                `;
                document
                    .getElementById("toggleDescription")
                    .addEventListener("click", function () {
                        if (!isExpanded) {
                            document.getElementById("descriptionText").innerHTML = description;
                            this.textContent = "收起";
                            isExpanded = true;
                        } else {
                            // 收起时也要根据条件显示不同的截断内容
                            let truncated = "";
                            if (lineCount > MAX_LINES) {
                                const lines = plainDesc.split('\n');
                                truncated = lines.slice(0, MAX_LINES).join('\n') + "...";
                            } else {
                                truncated = plainDesc.substring(0, MAX_LENGTH) + "...";
                            }
                            document.getElementById("descriptionText").innerHTML =
                                truncated.replace(/\n/g, "<br>");
                            this.textContent = "展开更多";
                            isExpanded = false;
                        }
                    });
            } else {
                descContainer.innerHTML = `<p class="text-gray-700">${description}</p>`;
            }

            modal.classList.remove("hidden");
            // 异步加载下载历史图表
            if (app && app.pkg_name) {
                const pkgName = app.pkg_name;
                fetch(`${API_BASE}/apps/metrics/${pkgName}`)
                    .then((response) => {
                        if (!response.ok) {
                            throw new Error("Network response was not ok");
                        }
                        return response.json();
                    })
                    .then((historyResult) => {
                        // 原始数据是从新到旧
                        let history = historyResult.data || [];
                        history.reverse();
                        // 过滤的同时去重：过滤新日期下载量小于等于旧日期的（同时去除重复的download_count）
                        if (Array.isArray(history) && history.length > 1) {
                            const filtered = [history[0]];
                            for (let i = 1; i < history.length; i++) {
                                if (history[i].download_count > filtered[filtered.length - 1].download_count) {
                                    filtered.push(history[i]);
                                }
                            }
                            history = filtered;
                        }

                        const chartCanvas = document.getElementById("downloadHistoryChart");
                        const incrementCanvas = document.getElementById(
                            "downloadIncrementChart",
                        );
                        const noHistoryMsg = document.getElementById("noHistoryMessage");
                        const noIncrementMsg = document.getElementById("noIncrementMessage");

                        if (history.length > 1) {
                            /**
                             * @type {Array} 下载量历史数据
                             */
                            const downloadData = history.map((item) => ({
                                x: new Date(item.created_at),
                                y: item.download_count,
                            }));

                            // 计算增量数据和平均每小时增量数据
                            /**
                             * @type {Array} 下载增量数据
                             */
                            const increments = [];
                            /**
                             * @type {Array} 平均每小时增量数据
                             */
                            const hourlyIncrements = [];
                            /**
                             * @type {Array} 每日0点增量数据
                             */
                            const dailyIncrements = [];

                            if (history.length > 0) {
                                // 添加第一个点，y为0，x为下载量的第一个时间
                                increments.push({
                                    x: new Date(history[0].created_at),
                                    y: 0,
                                });
                                hourlyIncrements.push({
                                    x: new Date(history[0].created_at),
                                    y: 0,
                                });
                            }

                            for (let i = 1; i < history.length; i++) {
                                const increment =
                                    history[i].download_count - history[i - 1].download_count;

                                increments.push({
                                    x: new Date(history[i].created_at),
                                    y: Math.max(increment, 0),
                                });

                                // 计算平均每小时增量
                                const timeDiff =
                                    (new Date(history[i].created_at) -
                                        new Date(history[i - 1].created_at)) /
                                    (1000 * 60 * 60); // 转换为小时
                                const hourlyIncrement = timeDiff > 0 ? increment / timeDiff : 0;
                                hourlyIncrements.push({
                                    x: new Date(history[i].created_at),
                                    y: Math.max(Math.round(hourlyIncrement), 0), // 取整，避免小数过多
                                });
                            }

                            // 把增量的第一个点的y值设置为第二个点的y值
                            if (increments.length > 1) {
                                increments[0].y = increments[1].y;
                                hourlyIncrements[0].y = hourlyIncrements[1].y;
                            }

                            // 计算每日0点的增量数据
                            if (history.length > 0) {
                                // 按日期分组，找到每天0点或接近0点的数据
                                const dailyData = new Map();

                                for (let i = 0; i < history.length; i++) {
                                    const date = new Date(history[i].created_at);
                                    const dateKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

                                    if (!dailyData.has(dateKey)) {
                                        dailyData.set(dateKey, {
                                            date: new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0),
                                            downloadCount: history[i].download_count,
                                            index: i
                                        });
                                    }
                                }

                                // 将Map转换为数组并排序
                                const sortedDailyData = Array.from(dailyData.values()).sort((a, b) => a.date - b.date);

                                // 计算每日增量
                                for (let i = 0; i < sortedDailyData.length; i++) {
                                    if (i === 0) {
                                        // 第一天，增量为0
                                        dailyIncrements.push({
                                            x: sortedDailyData[i].date,
                                            y: 0
                                        });
                                    } else {
                                        // 计算当天与前一天的下载量差值
                                        const increment = sortedDailyData[i].downloadCount - sortedDailyData[i - 1].downloadCount;
                                        dailyIncrements.push({
                                            x: sortedDailyData[i].date,
                                            y: Math.max(increment, 0)
                                        });
                                    }
                                }
                            }

                            /**
                             * @type {Object} 图表插件配置
                             */
                            const chart_plugin = {
                                legend: { display: true, position: "top" },
                                tooltip: {
                                    callbacks: {
                                        // 顶部标题行（时间）
                                        title: function (contexts) {
                                            const date = new Date(contexts[0].parsed.x);
                                            return DashboardUtils.formatDate(date);
                                        },
                                        label: function (context) {
                                            return `下载量: ${DashboardUtils.formatNumber(context.parsed.y)}`;
                                        },
                                    },
                                },
                            };

                            // 创建下载量图表（原有）
                            const ctx = chartCanvas.getContext("2d");
                            window.downloadHistoryChart = new Chart(ctx, {
                                type: "line",
                                data: {
                                    datasets: [{
                                        label: "下载量",
                                        data: downloadData,
                                        borderColor: "rgb(59, 130, 246)",
                                        backgroundColor: "rgba(59, 130, 246, 0.1)",
                                        fill: true,
                                        tension: 0.1,
                                    },],
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        x: {
                                            type: "time",
                                            title: { display: true, text: "日期" },
                                            time: {
                                                displayFormats: {
                                                    minute: "yyyy-MM-dd HH:mm",
                                                    hour: "yyyy-MM-dd HH:mm",
                                                    day: "yyyy-MM-dd HH:mm",
                                                },
                                            },
                                            ticks: {
                                                callback: function (value) {
                                                    const date = new Date(value);
                                                    return DashboardUtils.formatDate(date);
                                                },
                                            },
                                        },
                                        y: {
                                            beginAtZero: false,
                                            ticks: {
                                                callback: function (value) {
                                                    return DashboardUtils.formatNumber(value);
                                                },
                                            },
                                        },
                                    },
                                    plugins: chart_plugin,
                                },
                            });

                            // 创建增量图表，包含总增量和平均每小时增量
                            if (increments.length > 0) {
                                const incrementCtx = incrementCanvas.getContext("2d");

                                // 修改tooltip以区分两个数据集
                                /**
                                 * @type {Object} 增量图表插件配置
                                 */
                                const incrementChartPlugin = {
                                    legend: { display: true, position: "top" },
                                    tooltip: {
                                        callbacks: {
                                            title: function (contexts) {
                                                const date = new Date(contexts[0].parsed.x);
                                                return DashboardUtils.formatDate(date);
                                            },
                                            label: function (context) {
                                                const datasetLabel = context.dataset.label || "";
                                                if (datasetLabel === "下载增量") {
                                                    return `下载增量: ${DashboardUtils.formatNumber(context.parsed.y)}`;
                                                } else if (datasetLabel === "平均每小时增量") {
                                                    return `平均每小时增量: ${DashboardUtils.formatNumber(context.parsed.y)}`;
                                                } else if (datasetLabel === "每日增量") {
                                                    return `每日增量: ${DashboardUtils.formatNumber(context.parsed.y)}`;
                                                }
                                                return `${datasetLabel}: ${DashboardUtils.formatNumber(context.parsed.y)}`;
                                            },
                                        },
                                    },
                                };

                                window.downloadIncrementChart = new Chart(incrementCtx, {
                                    type: "line",
                                    data: {
                                        datasets: [

                                            {
                                                label: "每日增量",
                                                data: dailyIncrements,
                                                borderColor: "rgb(34, 197, 94)",
                                                backgroundColor: "rgba(34, 197, 94, 0.1)",
                                                fill: true,
                                                tension: 0.1,
                                            }, {
                                                label: "下载增量",
                                                data: increments,
                                                borderColor: "rgb(59, 130, 246)",
                                                backgroundColor: "rgba(59, 130, 246, 0.1)",
                                                fill: true,
                                                tension: 0.1,
                                                hidden: true,
                                            },
                                            {
                                                label: "平均每小时增量",
                                                data: hourlyIncrements,
                                                borderColor: "rgb(255, 99, 132)",
                                                backgroundColor: "rgba(255, 99, 132, 0.1)",
                                                fill: true,
                                                tension: 0.1,
                                                hidden: true,
                                            }
                                        ],
                                    },
                                    options: {
                                        responsive: true,
                                        maintainAspectRatio: false,
                                        scales: {
                                            x: {
                                                type: "time",
                                                title: { display: true, text: "日期" },
                                                time: {
                                                    displayFormats: {
                                                        minute: "yyyy-MM-dd HH:mm",
                                                        hour: "yyyy-MM-dd HH:mm",
                                                        day: "yyyy-MM-dd HH:mm",
                                                    },
                                                },
                                                ticks: {
                                                    callback: function (value) {
                                                        const date = new Date(value);
                                                        return DashboardUtils.formatDate(date);
                                                    },
                                                },
                                            },
                                            y: {
                                                beginAtZero: false,
                                                title: { display: true, text: "下载量" },
                                                ticks: {
                                                    callback: function (value) {
                                                        return DashboardUtils.formatNumber(value);
                                                    },
                                                },
                                            },
                                        },
                                        plugins: incrementChartPlugin,
                                    },
                                });
                                incrementCanvas.style.display = "block";
                                noIncrementMsg.classList.add("hidden");
                            } else {
                                incrementCanvas.style.display = "none";
                                noIncrementMsg.classList.remove("hidden");
                            }

                            // 显示原有图表
                            chartCanvas.style.display = "block";
                            noHistoryMsg.classList.add("hidden");
                        } else {
                            // 无数据：隐藏两个图表
                            chartCanvas.style.display = "none";
                            incrementCanvas.style.display = "none";
                            noHistoryMsg.classList.remove("hidden");
                            noIncrementMsg.classList.remove("hidden");
                        }
                    })
                    .catch((historyError) => {
                        // 错误处理（原有，扩展到两个图表）
                        console.error("Failed to load download history:", historyError);
                        document.getElementById("downloadHistoryChart").style.display =
                            "none";
                        document.getElementById("downloadIncrementChart").style.display =
                            "none";
                        document.getElementById("noHistoryMessage").innerHTML =
                            "加载历史数据失败";
                        document.getElementById("noIncrementMessage").innerHTML =
                            "加载历史数据失败";
                        document
                            .getElementById("noHistoryMessage")
                            .classList.remove("hidden");
                        document
                            .getElementById("noIncrementMessage")
                            .classList.remove("hidden");
                    });
            } else {
                document.getElementById("downloadHistoryChart").style.display = "none";
                document.getElementById("noHistoryMessage").classList.remove("hidden");
            }
        } catch (error) {
            console.error("Failed to load app details:", error);
            document.getElementById("appDetailContent").innerHTML =
                '<div class="text-center py-4 text-red-500">Failed to load details</div>';
            document.getElementById("appDetailModal").classList.remove("hidden");
        }
    }

    return {
        showAppDetail: showAppDetail
    };
})();
