// 应用市场仪表板 JavaScript 文件
// 提供应用列表、统计图表、搜索排序等功能

// ==============================================
// 全局变量定义
// ==============================================

/**
 * @type {number} 当前页码，从1开始
 */
let currentPage = 1;

/**
 * @type {number} 总页数，根据数据总量和分页大小计算
 */
let totalPages = 1;

/**
 * @type {Object} 当前打开的应用详情
 * @property {string} appId - 应用ID
 * @property {string} pkgName - 包名
 */
let currentApp = {};

/**
 * @type {Object} 当前排序配置
 * @property {string} field - 排序字段名
 * @property {boolean} desc - 是否降序排列
 */
let currentSort = { field: "download_count", desc: true };

/**
 * @type {string} 搜索关键词，用于过滤应用列表
 */
let searchTerm = "";

let searchKey = "name";
let searchExact = false;
let excludeHuawei = false;
let excludeAtomic = false;

/**
 * 解析链接提取包名
 */
function parseLink() {
    const linkInput = document.getElementById("linkInput");
    const pkgInput = document.getElementById("pkgInput");
    const linkError = document.getElementById("linkError");

    const link = linkInput.value.trim();
    if (!link) {
        linkError.classList.add("hidden");
        return;
    }

    const regex = /(?<=id=)[\w\.]+/;
    const match = link.match(regex);
    if (match) {
        pkgInput.value = match[0];
        linkError.classList.add("hidden");
    } else {
        pkgInput.value = "";
        linkError.classList.remove("hidden");
    }
}

/**
 * 校验输入
 * @returns {boolean} 是否通过校验
 */
function validateInputs() {
    const pkgInput = document.getElementById("pkgInput").value.trim();
    const appIdInput = document.getElementById("appIdInput").value.trim();
    const pkgError = document.getElementById("pkgError");
    const appIdError = document.getElementById("appIdError");

    let valid = true;

    // 二选一必填
    if (!pkgInput && !appIdInput) {
        pkgError.textContent = "包名或 app_id 必须填写其中一个";
        pkgError.classList.remove("hidden");
        appIdError.classList.add("hidden");
        valid = false;
    } else if (pkgInput && !appIdInput) {
        // 校验包名
        const pkgRegex = /^[a-zA-Z0-9_\.]+$/;
        if (!pkgRegex.test(pkgInput)) {
            pkgError.classList.remove("hidden");
            valid = false;
        } else {
            pkgError.classList.add("hidden");
        }
        appIdError.classList.add("hidden");
    } else if (!pkgInput && appIdInput) {
        // 校验 app_id 非空
        if (!appIdInput) {
            appIdError.classList.remove("hidden");
            valid = false;
        } else {
            appIdError.classList.add("hidden");
        }
        pkgError.classList.add("hidden");
    } else {
        // 两者都填，优先用包名
        const pkgRegex = /^[a-zA-Z0-9_\.]+$/;
        if (!pkgRegex.test(pkgInput)) {
            pkgError.classList.remove("hidden");
            valid = false;
        } else {
            pkgError.classList.add("hidden");
        }
        appIdError.classList.add("hidden");
    }

    return valid;
}

/**
 * 查询应用
 */
async function queryApp() {
    const pkgName = document.getElementById("pkgInput").value.trim();
    const appId = document.getElementById("appIdInput").value.trim();
    const username = document.getElementById("usernameInput").value.trim();
    const remark = document.getElementById("remarkInput").value.trim();
    const resultArea = document.getElementById("resultArea");

    // 保存用户名到本地存储
    if (username) {
        localStorage.setItem('submitUsername', username);
    }

    let submit_body = {};
    if (pkgName) {
        submit_body.pkg_name = pkgName;
    } else if (appId) {
        const modifiedAppId = appId.startsWith('C') ? appId : 'C' + appId;
        submit_body.app_id = modifiedAppId;
    } else {
        alert("请输入包名或 app_id");
        return;
    }

    let comment = {};
    // 添加可选的用户名和备注
    if (username) {
        comment.user = username;
    }
    if (remark) {
        comment.comment = remark;
    }
    if (comment) {
        submit_body.comment = comment;
    }

    const url = `${API_BASE}/submit`;
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(submit_body)
        });
        if (!response.ok) {
            throw new Error("查询失败");
        }
        const data = await response.json();
        if (data.success) {
            renderResult(data.data);
            resultArea.classList.remove("hidden");
        } else {
            alert("查询失败，请检查输入");
            resultArea.classList.add("hidden");
        }
    } catch (error) {
        console.error("查询错误:", error);
        alert("查询失败，请检查输入");
        resultArea.classList.add("hidden");
    }
}

/**
 * 渲染查询结果
 * @param {Object} data - API 返回数据
 */
function renderResult(data) {
    const resultContent = document.getElementById("resultContent");
    const { full_info, new_app, new_info, new_metric, new_rating } = data;
    const is_new = !!(new_app || new_info || new_metric || new_rating);

    if (!info || !metric) {
        resultContent.innerHTML = "<p class='text-red-500'>未找到应用信息</p>";
        return;
    }

    const iconUrl = full_info.icon_url || '';
    const downloadCount = full_info.download_count || 0;
    const name = full_info.name || '未知应用';
    const same_css = `<span class="bg-green-100 text-green-800 px-2 py-1 rounded-xl text-xs`;

    resultContent.innerHTML = `
        <div class="flex items-center space-x-3 mb-2">
            ${iconUrl ? `<img src="${iconUrl}" alt="图标" class="w-12 h-12 rounded-xl object-cover">` : '<div class="w-12 h-12 bg-gray-300 rounded-xl"></div>'}
            <div>
                <h4 class="font-semibold">${name}</h4>
                <p class="text-sm text-gray-600">包名: ${full_info.pkg_name || 'N/A'}</p>
                ${full_info.average_rating ? `<p class="text-sm text-gray-600">评分: ${full_info.average_rating || 'N/A'} (${full_info.total_ratings || 0} 人评价)</p>` : ''}
                ${new_app ? `${same_css} ml-3">是新APP！</span>` : ''}
                ${new_info ? `${same_css} ml-2">基本信息有更新</span>` : ''}
                ${new_metric ? `${same_css} ml-2">指标数据有更新</span>` : ''}
                ${new_rating ? `${same_css} ml-2">评分有更新</span>` : ''}
                ${is_new ? `<span class="bg-gray-100 text-gray-800 px-2 py-1 rounded-xl text-xs ml-2">暂无数据更新</span>` : ''}
            </div>
        </div>
        <div class="grid grid-cols-2 gap-2 text-sm">
            <div><strong>下载量:</strong> ${downloadCount > 10000 ? (downloadCount / 10000).toFixed(1) + '万' : downloadCount}</div>
            <div><strong>大小:</strong> ${(full_info.size_bytes / 1024 / 1024).toFixed(1)} MB</div>
            <div><strong>版本:</strong> ${full_info.version}</div>
            <div><strong>价格:</strong> ${full_info.price}</div>
            <div><strong>开发者:</strong> ${full_info.developer_name}</div>
            <div><strong>分类:</strong> ${full_info.kind_name}</div>
        </div>
    `;
}

/**
 * @type {number} 每页显示的应用数量
 */
const PAGE_SIZE = 20;

/**
 * @type {string} API基础路径，根据部署环境调整
 */
const API_BASE = "/api/v0";

// ==============================================
// 工具函数
// ==============================================

/**
 * 更新最后更新时间戳
 */
function updateLastUpdate() {
    const now = new Date();
    document.getElementById("lastUpdate").textContent =
        now.toLocaleString("zh-CN");
}

// ==============================================
// 事件监听器
// ==============================================

// ESC键关闭详情弹窗
document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
        const modalsToClose = ["appDetailModal", "helpModal", "submitModal", "contactModal", "searchHelpModal", "changelogModal"];
        modalsToClose.forEach(modalId => {
            const modal = document.getElementById(modalId);
            if (!modal.classList.contains("hidden")) {
                modal.classList.add("hidden");

                // 如果关闭的是应用详情模态框，移除URL参数
                if (modalId === "appDetailModal") {
                    window.updateUrlParam('app_id', '');
                    window.updateUrlParam('pkg_name', '');
                    window.currentApp = null;
                }
            }
        });
    }
});

/**
 * 获取当前URL参数
 * @returns {Object} URL参数对象
 */
window.getUrlParams = function () {
    const params = {};
    new URLSearchParams(window.location.search).forEach((value, key) => {
        params[key] = value;
    });
    return params;
}

/**
 * 更新URL参数，不刷新页面
 * @param {string} key - 参数名
 * @param {string} value - 参数值
 */
window.updateUrlParam = function (key, value) {
    const url = new URL(window.location);
    if (value) {
        url.searchParams.set(key, value);
    } else {
        url.searchParams.delete(key);
    }
    window.history.pushState({}, '', url);
}

/**
 * 复制文本到剪贴板
 * @param {string} text - 要复制的文本
 * @param {HTMLElement} [button] - 触发复制的按钮元素
 */
window.copyToClipboard = function (text, button) {
    // 检查navigator.clipboard是否存在
    if (!navigator.clipboard) {
        // 如果不支持clipboard API，使用回退方案
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.opacity = '0';
        document.body.appendChild(textArea);
        textArea.select();

        try {
            const successful = document.execCommand('copy');
            document.body.removeChild(textArea);

            if (successful) {
                showCopySuccess(button);
            } else {
                showCopyError(button);
            }
        } catch (err) {
            document.body.removeChild(textArea);
            console.error('复制失败:', err);
            showCopyError(button);
        }
        return;
    }

    // 使用现代clipboard API
    navigator.clipboard.writeText(text).then(() => {
        showCopySuccess(button);
    }).catch(err => {
        console.error('复制失败:', err);
        showCopyError(button);
    });

    // 成功提示函数
    function showCopySuccess(button) {
        if (button) {
            const originalText = button.textContent;
            const originalBg = button.style.background;
            button.textContent = '复制成功！';
            button.style.background = 'linear-gradient(to right, #10B981, #059669)';

            setTimeout(() => {
                button.textContent = originalText;
                button.style.background = originalBg;
            }, 2000);
        } else {
            // 创建一个浮动提示
            const toast = document.createElement('div');
            toast.textContent = '链接已复制到剪贴板！';
            toast.style.cssText = 'position:fixed; bottom:20px; left:50%; transform:translateX(-50%); background-color:rgba(16,185,129,0.9); color:white; padding:10px 20px; border-radius:4px; z-index:9999; box-shadow:0 4px 6px rgba(0,0,0,0.1); transition:all 0.3s ease;';
            document.body.appendChild(toast);

            // 2秒后移除提示
            setTimeout(() => {
                toast.style.opacity = '0';
                setTimeout(() => document.body.removeChild(toast), 300);
            }, 2000);
        }
    }

    // 失败提示函数
    function showCopyError(button) {
        if (button) {
            const originalText = button.textContent;
            const originalBg = button.style.background;
            button.textContent = '复制失败！';
            button.style.background = 'linear-gradient(to right, #EF4444, #DC2626)';

            setTimeout(() => {
                button.textContent = originalText;
                button.style.background = originalBg;
            }, 2000);
        } else {
            const toast = document.createElement('div');
            toast.textContent = '复制失败，请手动复制。';
            toast.style.cssText = 'position:fixed; bottom:20px; left:50%; transform:translateX(-50%); background-color:rgba(239,68,68,0.9); color:white; padding:10px 20px; border-radius:4px; z-index:9999; box-shadow:0 4px 6px rgba(0,0,0,0.1); transition:all 0.3s ease;';
            document.body.appendChild(toast);

            setTimeout(() => {
                toast.style.opacity = '0';
                setTimeout(() => document.body.removeChild(toast), 300);
            }, 2000);
        }
    }
}

/**
 * 使用系统分享API分享链接
 * @param {string} title - 分享标题
 * @param {string} text - 分享文本
 * @param {string} url - 分享链接
 */
window.shareLink = function (title, text, url) {
    if (navigator.share) {
        navigator.share({
            title: title,
            text: text,
            url: url
        }).catch(err => {
            console.error('分享失败:', err);
            alert('分享失败，请手动分享。');
        });
    } else {
        const toast = document.createElement('div');
        toast.textContent = '您的浏览器不支持系统分享功能，已复制链接到剪贴板。';
        toast.style.cssText = 'position:fixed; bottom:20px; left:50%; transform:translateX(-50%); background-color:rgba(79,70,229,0.9); color:white; padding:10px 20px; border-radius:4px; z-index:9999; box-shadow:0 4px 6px rgba(0,0,0,0.1); transition:all 0.3s ease;';
        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.opacity = '0';
            setTimeout(() => document.body.removeChild(toast), 300);
        }, 2000);

        window.copyToClipboard(url);
    }
}

// DOM加载完成后初始化
document.addEventListener("DOMContentLoaded", () => {
    // 检查URL参数，如果有app_id或pkg_name参数，自动打开应用详情
    const params = window.getUrlParams();
    const appId = params.app_id;
    const pkgName = params.pkg_name;

    DashboardDataLoaders.loadOverview();
    DashboardDataLoaders.loadApps();
    document.getElementById("searchKeySelect").value = "name";
    DashboardCharts.loadCharts();
    updateLastUpdate();

    // 使用 SSE 实时更新同步状态
    function initSyncStatusSSE() {
        const sseUrl = `${API_BASE}/sync_status/stream`;

        SSEManager.connect(
            sseUrl,
            // onMessage - 收到同步状态更新
            function (syncStatus) {
                DashboardDataLoaders.updateSyncStatus(syncStatus);
            },
            // onError - 连接错误处理
            function (error) {
                console.error("SSE 连接错误，回退到轮询模式:", error);
                // 如果 SSE 连接失败，回退到轮询模式
                fallbackToPolling();
            },
            // onOpen - 连接成功
            function (event) {
                console.log("同步状态 SSE 连接已建立");
            }
        );
    }

    // 回退到轮询模式（当 SSE 连接失败时）
    function fallbackToPolling() {
        console.log("使用轮询模式更新同步状态");
        setInterval(async () => {
            try {
                const response = await fetch(`${API_BASE}/market_info`);
                const market_info = await response.json();
                const sync_status = market_info.data.sync_status;
                DashboardDataLoaders.updateSyncStatus(sync_status);
            } catch (error) {
                console.error("轮询更新同步状态失败:", error);
            }
        }, 5000); // 改为5秒间隔，减少服务器压力
    }

    initSyncStatusSSE();

    // 如果有app_id参数，打开应用详情
    if (appId) {
        setTimeout(() => {
            DashboardAppDetails.showAppDetail(appId);
        }, 1000);
    }
    // 如果有pkg_name参数，通过API查询后打开详情
    else if (pkgName) {
        setTimeout(async () => {
            try {
                const response = await fetch(`${API_BASE}/apps/pkg_name/${pkgName}`);
                const data = await response.json();
                if (data.data && data.data.info && data.data.info.app_id) {
                    DashboardAppDetails.showAppDetail(data.data.info.app_id);
                }
            } catch (error) {
                console.error('根据包名查询应用失败:', error);
            }
        }, 1000);
    }

    // Sorting event listeners
    document.querySelectorAll("th[data-sort]").forEach((header) => {
        header.addEventListener("click", () => {
            const field = header.getAttribute("data-sort");
            // 默认升序，但对 listed_at 字段第一次点击设置为降序（最新应用在前）
            let desc = false;
            if (field === "listed_at") {
                desc = true;
            }
            if (field === currentSort.field) {
                // 如果是同一字段，则切换排序方向
                desc = currentSort.desc === false ? true : false;
            }
            currentSort = { field, desc };
            DashboardRenderers.updateSortIcons();
            DashboardDataLoaders.loadApps(1);
        });
    });

    // Search button
    document.getElementById("searchBtn").addEventListener("click", () => {
        const searchValue = document.getElementById("searchInput").value.trim();
        if (!searchValue) {
            searchTerm = "";
            DashboardDataLoaders.loadApps(1);
            return;
        }
        searchKey = document.getElementById("searchKeySelect").value;
        searchExact = document.getElementById("searchExact").checked;
        excludeHuawei = document.getElementById("excludeHuawei").checked;
        excludeAtomic = document.getElementById("excludeAtomic").checked;
        searchTerm = searchValue;
        DashboardDataLoaders.loadApps(1);
    });

    // Search input enter key
    document.getElementById("searchInput").addEventListener("keypress", (e) => {
        if (e.key === "Enter") {
            const searchValue = e.target.value.trim();
            if (!searchValue) {
                searchTerm = "";
                DashboardDataLoaders.loadApps(1);
                return;
            }
            searchKey = document.getElementById("searchKeySelect").value;
            searchExact = document.getElementById("searchExact").checked;
            excludeHuawei = document.getElementById("excludeHuawei").checked;
            excludeAtomic = document.getElementById("excludeAtomic").checked;
            searchTerm = searchValue;
            DashboardDataLoaders.loadApps(1);
        }
    });

    // Clear search button
    document.getElementById("clearSearchBtn").addEventListener("click", () => {
        // 清空搜索输入框
        document.getElementById("searchInput").value = "";

        // 重置搜索下拉框为默认值
        document.getElementById("searchKeySelect").value = "name";

        // 取消所有复选框
        document.getElementById("searchExact").checked = false;
        document.getElementById("excludeHuawei").checked = false;
        document.getElementById("excludeAtomic").checked = false;

        // 清空搜索变量
        searchTerm = "";
        searchKey = "name";
        searchExact = false;
        excludeHuawei = false;
        excludeAtomic = false;

        // 重新加载数据
        DashboardDataLoaders.loadApps(1);
    });

    // Refresh button
    document.getElementById("refreshBtn").addEventListener("click", DashboardDataLoaders.refreshData);

    // 更新日志加载状态
    let changelogLoaded = false;

    // 加载更新日志内容
    async function loadChangelog() {
        if (changelogLoaded) return;

        const contentDiv = document.querySelector('#changelogModal .flex-1.overflow-y-auto');
        if (!contentDiv) return;

        try {
            contentDiv.innerHTML = '<div class="flex items-center justify-center h-full"><div class="text-indigo-600">加载中...</div></div>';

            const response = await fetch('/update.md');
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const markdown = await response.text();

            // 使用 markdown-it 进行渲染
            const md = new window.markdownit({
                html: false, // Disallow raw HTML in markdown for security
                linkify: true, // Auto-convert URL-like text to links
                typographer: true // Enable smart typography
            });

            // Custom renderers to add Tailwind CSS classes
            // Headings (h1-h6)
            const originalHeadingOpen = md.renderer.rules.heading_open;
            md.renderer.rules.heading_open = function (tokens, idx, options, env, self) {
                const token = tokens[idx];
                const headingClasses = {
                    'h1': 'text-2xl font-bold mb-4 border-b pb-2 text-indigo-700',
                    'h2': 'text-xl font-semibold mb-3 pt-2 text-indigo-600',
                    'h3': 'text-lg font-medium mb-2 pt-1 text-indigo-500',
                    'h4': 'text-base font-medium mb-1',
                    'h5': 'text-sm font-medium mb-1',
                    'h6': 'text-sm font-normal mb-1'
                };
                token.attrJoin('class', headingClasses[token.tag] || '');
                return originalHeadingOpen ? originalHeadingOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Paragraphs
            const originalParagraphOpen = md.renderer.rules.paragraph_open;
            md.renderer.rules.paragraph_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'mb-3 leading-relaxed');
                return originalParagraphOpen ? originalParagraphOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Links
            const originalLinkOpen = md.renderer.rules.link_open;
            md.renderer.rules.link_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'text-blue-600 hover:underline');
                return originalLinkOpen ? originalLinkOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Lists (ul, ol, li)
            const originalListItemOpen = md.renderer.rules.list_item_open;
            md.renderer.rules.list_item_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'mb-1');
                return originalListItemOpen ? originalListItemOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };
            const originalBulletListOpen = md.renderer.rules.bullet_list_open;
            md.renderer.rules.bullet_list_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'list-disc pl-5 mb-3');
                return originalBulletListOpen ? originalBulletListOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };
            const originalOrderedListOpen = md.renderer.rules.ordered_list_open;
            md.renderer.rules.ordered_list_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'list-decimal pl-5 mb-3');
                return originalOrderedListOpen ? originalOrderedListOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Inline code
            const originalCodeInline = md.renderer.rules.code_inline;
            md.renderer.rules.code_inline = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'bg-gray-200 text-red-700 px-1 py-0.5 rounded text-sm font-mono');
                return originalCodeInline ? originalCodeInline(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Code blocks (fences)
            const originalFence = md.renderer.rules.fence;
            md.renderer.rules.fence = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'bg-gray-100 p-3 rounded-md overflow-x-auto my-3 text-sm font-mono');
                return originalFence ? originalFence(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Blockquotes
            const originalBlockquoteOpen = md.renderer.rules.blockquote_open;
            md.renderer.rules.blockquote_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'border-l-4 border-indigo-500 pl-4 italic text-gray-700 my-4');
                return originalBlockquoteOpen ? originalBlockquoteOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            // Tables
            const originalTableOpen = md.renderer.rules.table_open;
            md.renderer.rules.table_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'w-full text-left border-collapse my-4');
                return originalTableOpen ? originalTableOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };
            const originalThOpen = md.renderer.rules.th_open;
            md.renderer.rules.th_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'px-4 py-2 bg-gray-100 border border-gray-300 font-semibold');
                return originalThOpen ? originalThOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };
            const originalTdOpen = md.renderer.rules.td_open;
            md.renderer.rules.td_open = function (tokens, idx, options, env, self) {
                tokens[idx].attrJoin('class', 'px-4 py-2 border border-gray-300');
                return originalTdOpen ? originalTdOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
            };

            const html = md.render(markdown);

            contentDiv.innerHTML = html;
            changelogLoaded = true;
        } catch (error) {
            console.error('加载更新日志失败:', error);
            contentDiv.innerHTML = `
                <div class="flex flex-col items-center justify-center h-full text-center">
                    <div class="text-red-600 mb-2">加载更新日志失败</div>
                    <div class="text-gray-600 text-sm">${error.message}</div>
                </div>
            `;
        }
    }

    // Modal event handlers
    const modalHandlers = [
        { id: 'helpBtn', modal: 'helpModal', action: 'show' },
        { id: 'closeHelpModal', modal: 'helpModal', action: 'hide' },
        { id: 'closeHelpModalBtn', modal: 'helpModal', action: 'hide' },
        { id: 'searchHelpBtn', modal: 'searchHelpModal', action: 'show' },
        { id: 'closeSearchHelpModal', modal: 'searchHelpModal', action: 'hide' },
        { id: 'closeSearchHelpBtn', modal: 'searchHelpModal', action: 'hide' },
        { id: 'contactBtn', modal: 'contactModal', action: 'show' },
        { id: 'closeContactModal', modal: 'contactModal', action: 'hide' },
        { id: 'closeContactModalBtn', modal: 'contactModal', action: 'hide' },
        { id: 'closeSubmitModal', modal: 'submitModal', action: 'hide' },
        { id: 'changelogBtn', modal: 'changelogModal', action: 'show' },
        { id: 'closeChangelogModal', modal: 'changelogModal', action: 'hide' },
        { id: 'closeChangelogModalBtn', modal: 'changelogModal', action: 'hide' }
    ];

    modalHandlers.forEach(handler => {
        const element = document.getElementById(handler.id);
        const modal = document.getElementById(handler.modal);

        if (element && modal) {
            element.addEventListener('click', () => {
                if (handler.action === 'show') {
                    modal.classList.remove('hidden');

                    // 如果是打开更新日志模态框，加载内容
                    if (handler.modal === 'changelogModal') {
                        loadChangelog();
                    }
                } else {
                    modal.classList.add('hidden');

                    // 如果关闭的是应用详情模态框，移除URL参数
                    if (handler.modal === 'appDetailModal') {
                        window.updateUrlParam('app_id', '');
                        window.updateUrlParam('pkg_name', '');
                        window.currentApp = null;
                    }
                }
            });
        }
    });

    // 为应用详情的关闭按钮添加事件，移除URL参数
    document.querySelectorAll("button[onclick]").forEach(btn => {
        const originalOnClick = btn.getAttribute('onclick');
        if (originalOnClick.includes("appDetailModal") && originalOnClick.includes("classList.add('hidden')")) {
            btn.setAttribute('onclick', `${originalOnClick}; window.updateUrlParam('app_id', ''); window.updateUrlParam('pkg_name', ''); window.currentApp = null;`);
        }
    });


    // 清空表单函数
    function clearForm() {
        document.getElementById("linkInput").value = "";
        document.getElementById("pkgInput").value = "";
        document.getElementById("appIdInput").value = "";
        // 从localStorage中重新加载用户名
        const savedUsername = localStorage.getItem('submitUsername');
        if (savedUsername) {
            document.getElementById("usernameInput").value = savedUsername;
        } else {
            document.getElementById("usernameInput").value = "";
        }
        document.getElementById("remarkInput").value = "";
        document.getElementById("linkError").classList.add("hidden");
        document.getElementById("pkgError").classList.add("hidden");
        document.getElementById("appIdError").classList.add("hidden");
        document.getElementById("resultArea").classList.add("hidden");
    }
    // 清空按钮
    document.getElementById("clearBtn").addEventListener("click", clearForm);
    // 投稿按钮
    document.getElementById("submitBtn").addEventListener("click", () => {
        document.getElementById("submitModal").classList.remove("hidden");
        // 清空输入和错误
        clearForm();
        // 清空函数中已经处理了用户名的加载，无需重复
    });
    // 包名输入事件，隐藏错误
    document.getElementById("pkgInput").addEventListener("input", () => {
        document.getElementById("pkgError").classList.add("hidden");
    });
    // app_id 输入事件，隐藏错误
    document.getElementById("appIdInput").addEventListener("input", () => {
        document.getElementById("appIdError").classList.add("hidden");
    });
    // 链接输入事件
    document.getElementById("linkInput").addEventListener("input", parseLink);
    // 查询按钮
    document.getElementById("queryBtn").addEventListener("click", () => {
        if (validateInputs()) {
            queryApp();
        }
    });

    // 清除用户名存储的按钮事件
    document.getElementById("clearUsernameStorage").addEventListener("click", (e) => {
        e.stopPropagation(); // 防止事件冒泡
        localStorage.removeItem('submitUsername');
        document.getElementById("usernameInput").value = "";
    });
});
