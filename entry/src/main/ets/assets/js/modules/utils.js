// 工具函数模块
var DashboardUtils = (function () {
    /**
     * 格式化数字，四位一分隔（中文习惯）
     * @param {number} num - 要格式化的数字
     * @returns {string} 格式化后的字符串
     */
    function formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{4})+(?!\d))/g, ",");
    }

    /**
     * 格式化文件大小，自动选择合适的单位
     * @param {number} size - 文件大小（字节）
     * @returns {string} 格式化后的大小字符串
     */
    function formatSize(size) {
        if (size < 1024) return size + " B";
        if (size < 1024 * 1024) return (size / 1024).toFixed(2) + " KB";
        if (size < 1024 * 1024 * 1024)
            return (size / (1024 * 1024)).toFixed(2) + " MB";
        return (size / (1024 * 1024 * 1024)).toFixed(2) + " GB";
    }

    /**
     * 格式化日期时间，输出为YYYY-MM-DD HH:mm格式
     * @param {string|Date} dateInput - 日期时间字符串或Date对象
     * @returns {string} 格式化后的日期时间字符串
     */
    function formatDate(dateInput) {
        const date = new Date(dateInput);
        const pad = (n) => (n < 10 ? "0" + n : n);
        return (
            date.getFullYear() +
            "-" +
            pad(date.getMonth() + 1) +
            "-" +
            pad(date.getDate()) +
            " " +
            pad(date.getHours()) +
            ":" +
            pad(date.getMinutes())
        );
    }

    /**
     * 使用Unicode字符渲染星级评分显示
     * @param {number|string} rating - 评分值，范围0-5
     * @returns {string|null} 星级字符串，如果无评分返回null
     */
    function renderStars(rating) {
        if (rating === undefined || rating === null || rating === "") return "无评分";

        // 转换为数字类型
        const numRating = typeof rating === "string" ? parseFloat(rating) : rating;

        // 验证转换后的值
        if (isNaN(numRating)) return "无评分";

        const fullStars = Math.floor(numRating);
        const hasHalf = numRating % 1 >= 0.5;
        let stars = "";
        for (let i = 0; i < 5; i++) {
            if (i < fullStars) {
                stars += "★"; // 满星
            } else if (i === fullStars && hasHalf) {
                stars += "☆"; // 半星（简化表示，可替换为更好符号）
            } else {
                stars += "☆"; // 空星
            }
        }
        return stars + ` ${numRating.toFixed(1)}`;
    }

    /**
     * 解析鸿蒙 api 版本对应系统版本
     * @param {number} sdk - 鸿蒙 api 版本号
     * @returns {string} 系统版本字符串
     */
    function parse_sdk_version(sdk) {
        switch (sdk) {
            // case 3:
            //     return "2.0.0(3)";
            // case 4:
            //     return "2.1.0(4)";
            // case 5:
            //     return "2.1.1(5)";
            // case 6:
            //     return "2.2.0(6)";
            // case 7:
            //     return "3.0.0(7)";
            // case 8:
            //     return "3.0.0(8)";
            // case 9:
            //     return "3.1.0(9)";
            // case 10:
            //     return "5.0 alpha(10)";
            // case 11:
            //     return "5.0 beta(11)";
            case 12:
                return "5.0.0(12)";
            case 13:
                return "5.0.1(13)";
            case 14:
                return "5.0.2(14)";
            case 15:
                return "5.0.3(15)";
            case 16:
                return "5.0.4(16)";
            case 17:
                return "5.0.5(17)";
            case 18:
                return "5.1.0(18)";
            case 19:
                return "5.1.1(19)";
            case 20:
                return "6.0.0(20)";
            case 21:
                return "6.0.1(21)";
            default:
                return `${sdk}`;
        }
    }

    return {
        formatNumber: formatNumber,
        formatSize: formatSize,
        formatDate: formatDate,
        renderStars: renderStars,
        parse_sdk_version: parse_sdk_version,
    };
})();
