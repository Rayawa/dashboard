// 图表模块
var DashboardCharts = (function () {
    let rating_chart = null;
    let min_sdk_chart = null;
    let target_sdk_chart = null;

    /**
     * 渲染下载量柱状图
     * @async
     * @param {string} api_url - API接口地址
     * @param {string} ctx_id - Canvas元素ID
     * @param {number} [y_axis_ratio=0.999] - Y轴最小值比例
     */
    async function render_top_download_chart(
        api_url,
        ctx_id,
        y_axis_ratio = 0.999,
    ) {
        try {
            const response = await fetch(api_url);
            const data = await response.json();

            let apps = [];
            if (data.success && data.data) {
                apps = data.data.data.map((item) => ({
                    name: item.name,
                    download_count: item.download_count,
                    icon_url: item.icon_url,
                    app_id: item.app_id,
                    pkg_name: item.pkg_name,
                }));
            }

            if (apps.length === 0) {
                console.error("图表数据无效或为空:", data);
                return;
            }

            // 预加载图标图像，避免悬停时异步加载问题
            const preloadedImages = await preloadImages(apps);

            const minValue = Math.min(...apps.map((item) => item.download_count || 0));
            const yAxisMin = Math.floor(minValue * y_axis_ratio);

            createChart(ctx_id, apps, preloadedImages, yAxisMin);
        } catch (error) {
            console.error("加载下载量图表失败:", error);
        }
    }

    /**
     * 预加载应用图标图像
     * @async
     * @param {Array} apps - 应用数据数组
     * @returns {Promise<Array>} 预加载的图像数组
     */
    async function preloadImages(apps) {
        const preloadedImages = [];
        const loadPromises = apps.map((app, index) => {
            if (!app || !app.icon_url) {
                preloadedImages[index] = null;
                return Promise.resolve();
            }
            return new Promise((resolve) => {
                const img = new Image();
                img.crossOrigin = "anonymous";
                img.onload = () => {
                    preloadedImages[index] = img;
                    resolve();
                };
                img.onerror = () => {
                    preloadedImages[index] = null;
                    resolve();
                };
                img.src = app.icon_url;
            });
        });
        await Promise.all(loadPromises);
        return preloadedImages;
    }

    /**
     * 创建Chart.js图表实例
     * @param {string} ctx_id - Canvas元素ID
     * @param {Array} apps - 应用数据数组
     * @param {Array} preloadedImages - 预加载的图像数组
     * @param {number} yAxisMin - Y轴最小值
     */
    function createChart(ctx_id, apps, preloadedImages, yAxisMin) {
        const ctx = document.getElementById(ctx_id).getContext("2d");
        if (window[ctx_id + "_chart"]) {
            window[ctx_id + "_chart"].destroy();
        }

        // 自定义插件：在柱状图上绘制图标
        const iconPlugin = {
            id: "iconPlugin",
            afterDatasetsDraw(chart) {
                const { ctx } = chart;
                const meta = chart.getDatasetMeta(0);
                meta.data.forEach((bar, index) => {
                    const img = preloadedImages[index];
                    if (!img) return;

                    const x = bar.x;
                    const y = bar.y - 17;

                    ctx.drawImage(img, x - 10, y - 20, 20, 20);
                });
            },
        };

        // 点击事件处理插件
        const clickPlugin = {
            id: "clickPlugin",
            afterEvent(chart, args) {
                const { event } = args;
                if (event.type === 'click') {
                    const elements = chart.getElementsAtEventForMode(
                        event,
                        'nearest', { intersect: true },
                        false
                    );

                    if (elements.length > 0) {
                        const elementIndex = elements[0].index;
                        const app = apps[elementIndex];
                        if (app && app.app_id) {
                            // 打开应用详情页面
                            if (typeof DashboardAppDetails !== 'undefined' && typeof DashboardAppDetails.showAppDetail === 'function') {
                                DashboardAppDetails.showAppDetail(app.app_id);
                                // 更新URL参数
                                if (typeof window.updateUrlParam === 'function') {
                                    window.updateUrlParam('app_id', app.app_id);
                                }
                            } else {
                                console.warn('应用详情模块未加载或showAppDetail函数不存在');
                            }
                        }
                    }
                }
            }
        };

        window[ctx_id + "_chart"] = new Chart(ctx, {
            type: "bar",
            data: {
                labels: apps.map((item) =>
                    item.name ?
                        item.name.length > 10 ?
                            item.name.slice(0, 10) + "..." :
                            item.name :
                        "未知",
                ),
                datasets: [{
                    label: "下载量",
                    data: apps.map((item) => item.download_count || 0),
                    backgroundColor: "rgba(59, 130, 246, 0.6)",
                    borderColor: "rgba(59, 130, 246, 1)",
                    borderWidth: 1,
                },],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        min: yAxisMin,
                        ticks: {
                            callback: function (value) {
                                return DashboardUtils.formatNumber(value);
                            },
                        },
                    },
                },
                plugins: {
                    tooltip: {
                        callbacks: {
                            label: function (context) {
                                return `下载量: ${DashboardUtils.formatNumber(context.raw)}`;
                            },
                        },
                    },
                    datalabels: {
                        anchor: "end",
                        align: "end",
                        offset: -3,
                        color: "#333",
                        font: { family: "console", size: 12 },
                        formatter: function (value) {
                            return DashboardUtils.formatNumber(value);
                        },
                    },
                },

            },
            plugins: [ChartDataLabels, iconPlugin, clickPlugin],
        });
    }

    /**
     * 加载星级分布饼图
     * @async
     */
    async function load_rating_chart() {
        try {
            const response = await fetch(`${API_BASE}/charts/rating`);
            const data = await response.json();
            const starData = data.data || data;

            const ctx = document.getElementById("rating_chart").getContext("2d");
            if (rating_chart) rating_chart.destroy();

            const starValues = [
                starData.star_1 || 0,
                starData.star_2 || 0,
                starData.star_3 || 0,
                starData.star_4 || 0,
                starData.star_5 || 0,
            ];
            const total = starValues.reduce((a, b) => a + b, 0);

            // 创建带数字的标签
            const labels = [
                `无评分 ${starValues[0]}-${(starValues[0] / total * 100).toFixed(2)}%`,
                `[1-2)星 ${starValues[1]}-${(starValues[1] / total * 100).toFixed(2)}%`,
                `[2-3)星 ${starValues[2]}-${(starValues[2] / total * 100).toFixed(2)}%`,
                `[3-4)星 ${starValues[3]}-${(starValues[3] / total * 100).toFixed(2)}%`,
                `[4-5]星 ${starValues[4]}-${(starValues[4] / total * 100).toFixed(2)}%`,
            ];

            rating_chart = new Chart(ctx, {
                type: "pie",
                data: {
                    labels: labels,
                    datasets: [{
                        data: starValues,
                        backgroundColor: [
                            "#ef4444",
                            "#f97316",
                            "#eab308",
                            "#22c55e",
                            "#0ea5e9",
                        ],
                    },],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: "bottom",
                        },
                    },
                },
            });
        } catch (error) {
            console.error("加载星级分布图表失败:", error);
        }
    }
    async function load_sdk_charts() {
        try {
            const response_min_sdk = await fetch(`${API_BASE}/charts/min_sdk`);
            const response_target_sdk = await fetch(`${API_BASE}/charts/target_sdk`);
            let data_min_sdk = await response_min_sdk.json();
            let data_target_sdk = await response_target_sdk.json();
            data_min_sdk = data_min_sdk.data || data_min_sdk;
            data_target_sdk = data_target_sdk.data || data_target_sdk;

            const ctx_min_sdk = document.getElementById("min_sdk_chart").getContext("2d");
            const ctx_target_sdk = document.getElementById("target_sdk_chart").getContext("2d");

            if (min_sdk_chart) min_sdk_chart.destroy();
            if (target_sdk_chart) target_sdk_chart.destroy();

            // 生成不重复的颜色数组
            function generateColors(count) {
                const colors = [];
                const hueStep = 360 / count;
                for (let i = 0; i < count; i++) {
                    const hue = i * hueStep;
                    colors.push(`hsl(${hue}, 80%, 60%)`);  // 增加饱和度到80%
                }
                return colors;
            }

            // 创建 SDK 图表点击事件处理器工厂函数
            function createSdkClickHandler(data, searchKeyName, displayName) {
                return (event, elements) => {
                    if (elements.length > 0) {
                        const elementIndex = elements[0].index;
                        const sdkValue = data[elementIndex][0];

                        // 设置搜索参数
                        if (typeof searchKey !== 'undefined' && typeof searchTerm !== 'undefined' && typeof searchExact !== 'undefined') {
                            searchKey = searchKeyName;
                            searchTerm = sdkValue.toString();
                            searchExact = true;

                            // 更新UI
                            document.getElementById('searchKeySelect').value = searchKeyName;
                            document.getElementById('searchInput').value = sdkValue;
                            document.getElementById('searchExact').checked = true;

                            // 执行搜索
                            if (typeof DashboardDataLoaders !== 'undefined' && typeof DashboardDataLoaders.loadApps === 'function') {
                                DashboardDataLoaders.loadApps(1);
                            }
                        }
                    }
                };
            }

            const minSdkColors = generateColors(data_min_sdk.length);
            const targetSdkColors = generateColors(data_target_sdk.length);

            min_sdk_chart = new Chart(ctx_min_sdk, {
                type: "pie",
                data: {
                    labels: data_min_sdk.map(item => DashboardUtils.parse_sdk_version(item[0])),
                    datasets: [{
                        data: data_min_sdk.map(item => item[1]),
                        backgroundColor: minSdkColors,
                    },],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: "bottom",
                        },
                        tooltip: {
                            callbacks: {
                                afterBody: function(context) {
                                    const index = context[0].dataIndex;
                                    const sdkValue = data_min_sdk[index][0];
                                    const sdkName = DashboardUtils.parse_sdk_version(sdkValue);
                                    return `\n点击以搜索 minsdk=${sdkName} 的应用`;
                                }
                            }
                        }
                    },
                    onClick: createSdkClickHandler(data_min_sdk, 'minsdk', '最小SDK')
                }
            });

            target_sdk_chart = new Chart(ctx_target_sdk, {
                type: "pie",
                data: {
                    labels: data_target_sdk.map(item => DashboardUtils.parse_sdk_version(item[0])),
                    datasets: [{
                        data: data_target_sdk.map(item => item[1]),
                        backgroundColor: targetSdkColors,
                    },],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: "bottom",
                        },
                        tooltip: {
                            callbacks: {
                                afterBody: function(context) {
                                    const index = context[0].dataIndex;
                                    const sdkValue = data_target_sdk[index][0];
                                    const sdkName = DashboardUtils.parse_sdk_version(sdkValue);
                                    return `\n点击以搜索 target_sdk=${sdkName} 的应用`;
                                }
                            }
                        }
                    },
                    onClick: createSdkClickHandler(data_target_sdk, 'target_sdk', '目标SDK')
                }
            });

        } catch (error) {
            console.error("加载SDK分布图表失败:", error);
        }
    }

    /**
     * 加载所有图表
     * @async
     */
    async function loadCharts() {
        render_top_download_chart(
            `${API_BASE}/apps/list/1?page_size=30&sort=download_count&desc=true`,
            "top_download_chart",
            0.999,
        );
        render_top_download_chart(
            `${API_BASE}/apps/list/1?page_size=30&sort=download_count&desc=true&exclude_huawei=true`,
            "top_download_chart_not_huawei",
            0.9,
        );
        load_rating_chart();
        load_sdk_charts();
    }

    return {
        render_top_download_chart: render_top_download_chart,
        preloadImages: preloadImages,
        createChart: createChart,
        loadCharts: loadCharts
    };
})();
