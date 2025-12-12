// 渲染模块
var DashboardRenderers = (function () {
    /**
     * 渲染应用列表到表格
     * @param {Array} apps - 应用数据数组
     */
    function renderApps(apps) {
        const tableBody = document.getElementById("appTableBody");
        tableBody.innerHTML = "";

        if (!apps || apps.length === 0) {
            tableBody.innerHTML =
                '<tr><td colspan="9" class="text-center py-4 text-gray-500">未找到应用</td></tr>';
            return;
        }

        apps.forEach((app, index) => {

            const tr = document.createElement("tr");
            tr.className = "hover:bg-gray-50 cursor-pointer transition-colors";
            tr.onclick = () => {
                DashboardAppDetails.showAppDetail(app.app_id);
                // 更新URL参数
                window.updateUrlParam('app_id', app.app_id);
            };
            tr.innerHTML = `
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${(currentPage - 1) * PAGE_SIZE + index + 1}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <img src="${app.icon_url || "/img/default-app-icon.png"}" class="app-icon mr-3" alt="${app.name}">
                        <span class="font-medium text-gray-900">${app.name || "未知"}</span>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <span class="developer-name inline-flex items-center px-3 py-1 cursor-pointer border border-blue-200 rounded-lg bg-blue-50 hover:bg-blue-100 hover:border-blue-400 hover:text-blue-700 transition-all duration-200 shadow-sm hover:shadow-md text-blue-600" 
                          data-developer="${app.developer_name || ""}"
                          title="点击以搜索该开发者开发的app">
                        ${app.developer_name || "未知"}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-xl bg-blue-100 text-blue-800">${app.kind_type_name || "未知"}-${app.kind_name || "未知"}-${app.tag_name || "未知"}</span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${DashboardUtils.renderStars(app.average_rating)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${DashboardUtils.formatNumber(app.total_star_rating_count || -1)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${DashboardUtils.formatNumber(app.download_count || 0)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${DashboardUtils.formatSize(app.size_bytes || 0)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${DashboardUtils.formatDate(app.created_at)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(app.created_at).toLocaleDateString("zh-CN")}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(app.listed_at).toLocaleDateString("zh-CN")}</td>
            `;

            // 为开发者名称添加点击事件
            const developerSpan = tr.querySelector('.developer-name');
            if (developerSpan) {
                developerSpan.addEventListener('click', (e) => {
                    e.stopPropagation(); // 阻止事件冒泡，避免触发行的点击事件
                    const developerName = developerSpan.getAttribute('data-developer');
                    if (developerName && developerName !== "未知") {
                        // 设置搜索参数
                        searchKey = 'developer_name';
                        searchTerm = developerName;
                        searchExact = true;

                        // 更新UI
                        document.getElementById('searchKeySelect').value = 'developer_name';
                        document.getElementById('searchInput').value = developerName;
                        document.getElementById('searchExact').checked = true;

                        // 执行搜索
                        DashboardDataLoaders.loadApps(1);
                    }
                });
            }

            tableBody.appendChild(tr);
        });
    }

    /**
     * 更新表格排序图标状态
     */
    function updateSortIcons() {
        const headers = document.querySelectorAll("th[data-sort]");
        headers.forEach((header) => {
            const field = header.getAttribute("data-sort");
            const span = header.querySelector("span");
            if (!span) return;

            if (field === currentSort.field) {
                span.textContent = currentSort.desc === false ? "↑" : "↓";
                header.classList.add("bg-gray-100"); // 激活状态
            } else {
                span.textContent = "↑";
                header.classList.remove("bg-gray-100");
            }
        });
    }

    /**
     * 渲染分页控件（使用Tailwind CSS样式）
     */
    function renderPagination() {
        const paginationEl = document.getElementById("pagination");
        paginationEl.innerHTML = "";

        if (totalPages <= 1) return;

        const ul = document.createElement("ul");
        ul.className = "flex items-center space-x-1";

        // 第一页按钮
        const firstLi = document.createElement("li");
        firstLi.className = `flex ${currentPage === 1 ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`;
        const firstA = document.createElement("a");
        firstA.textContent = "1";
        if (currentPage === 1) {
            firstA.className = "px-3 py-2 text-sm font-medium rounded-xl border-blue-500 bg-blue-100 text-blue-800";
        } else {
            firstA.className = "px-3 py-2 text-sm font-medium rounded-xl border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100";
        }
        if (currentPage > 1) {
            firstA.onclick = (e) => {
                e.preventDefault();
                DashboardDataLoaders.loadApps(1);
            };
        }
        firstLi.appendChild(firstA);
        ul.appendChild(firstLi);

        // 上一页按钮
        const prevLi = document.createElement("li");
        prevLi.className = `flex ${currentPage === 1 ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`;
        const prevA = document.createElement("a");
        prevA.className =
            "px-3 py-2 text-sm font-medium rounded-xl border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100";
        prevA.textContent = "上一页";
        if (currentPage > 1) {
            prevA.onclick = (e) => {
                e.preventDefault();
                DashboardDataLoaders.loadApps(currentPage - 1);
            };
        }
        prevLi.appendChild(prevA);
        ul.appendChild(prevLi);

        // 页码数字
        const startPage = Math.max(1, currentPage - 2);
        const endPage = Math.min(totalPages, currentPage + 2);
        for (let i = startPage; i <= endPage; i++) {
            const li = document.createElement("li");
            li.className = `flex ${i === currentPage ? "z-10" : ""}`;
            const a = document.createElement("a");
            a.className = `px-3 py-2 text-sm font-medium rounded-xl border ${i === currentPage
                ? "border-blue-500 bg-blue-100 text-blue-800"
                : "border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100"
                }`;
            a.textContent = i;
            a.onclick = (e) => {
                e.preventDefault();
                DashboardDataLoaders.loadApps(i);
            };
            li.appendChild(a);
            ul.appendChild(li);
        }

        // 下一页按钮
        const nextLi = document.createElement("li");
        nextLi.className = `flex ${currentPage === totalPages ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`;
        const nextA = document.createElement("a");
        nextA.className =
            "px-3 py-2 text-sm font-medium rounded-xl border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100";
        nextA.textContent = "下一页";
        if (currentPage < totalPages) {
            nextA.onclick = (e) => {
                e.preventDefault();
                DashboardDataLoaders.loadApps(currentPage + 1);
            };
        }
        nextLi.appendChild(nextA);
        ul.appendChild(nextLi);

        // 最后一页按钮
        const lastLi = document.createElement("li");
        lastLi.className = `flex ${currentPage === totalPages ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`;
        const lastA = document.createElement("a");
        lastA.textContent = totalPages.toString();
        if (currentPage === totalPages) {
            lastA.className = "px-3 py-2 text-sm font-medium rounded-xl border-blue-500 bg-blue-100 text-blue-800";
        } else {
            lastA.className = "px-3 py-2 text-sm font-medium rounded-xl border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100";
        }
        if (currentPage < totalPages) {
            lastA.onclick = (e) => {
                e.preventDefault();
                DashboardDataLoaders.loadApps(totalPages);
            };
        }
        lastLi.appendChild(lastA);
        ul.appendChild(lastLi);

        // 页码输入和跳转按钮
        const inputLi = document.createElement("li");
        inputLi.className = "flex items-center space-x-1";
        const input = document.createElement("input");
        input.type = "number";
        input.min = 1;
        input.max = totalPages;
        input.value = currentPage;
        input.className = "px-2 py-2 text-sm border-blue-300 bg-blue-50 text-blue-900 rounded-xl w-16 text-center";
        const jumpBtn = document.createElement("button");
        jumpBtn.textContent = "跳转";
        jumpBtn.className = "px-3 py-2 text-sm font-medium rounded-xl bg-blue-500 text-white border-blue-500 hover:bg-blue-600";
        jumpBtn.onclick = (e) => {
            e.preventDefault();
            const page = parseInt(input.value);
            if (!isNaN(page) && page >= 1 && page <= totalPages) {
                DashboardDataLoaders.loadApps(page);
            } else {
                input.value = currentPage; // 重置无效输入
            }
        };
        inputLi.appendChild(input);
        inputLi.appendChild(jumpBtn);
        ul.appendChild(inputLi);

        paginationEl.appendChild(ul);
    }

    return {
        renderApps: renderApps,
        renderPagination: renderPagination,
        updateSortIcons: updateSortIcons
    };
})();
