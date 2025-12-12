/**
 * SSE (Server-Sent Events) 管理器
 * 用于管理实时同步状态更新
 */
const SSEManager = (function () {
    'use strict';

    let eventSource = null;
    let reconnectTimer = null;
    let isConnecting = false;
    let reconnectAttempts = 0;
    const MAX_RECONNECT_ATTEMPTS = 5;
    const RECONNECT_DELAY = 3000; // 3秒

    /**
     * 初始化 SSE 连接
     * @param {string} url - SSE 端点 URL
     * @param {Function} onMessage - 消息处理函数
     * @param {Function} onError - 错误处理函数
     * @param {Function} onOpen - 连接成功处理函数
     */
    function connect(url, onMessage, onError, onOpen) {
        if (eventSource || isConnecting) {
            console.warn('SSE 连接已存在或正在连接中');
            return;
        }

        isConnecting = true;
        console.log('正在建立 SSE 连接...');

        try {
            eventSource = new EventSource(url);

            // 监听同步状态事件
            eventSource.addEventListener('sync_status', function (event) {
                try {
                    const data = JSON.parse(event.data);
                    if (onMessage && typeof onMessage === 'function') {
                        onMessage(data);
                    }
                } catch (error) {
                    console.error('解析 SSE 消息失败:', error);
                }
            });

            // 连接成功
            eventSource.onopen = function (event) {
                console.log('SSE 连接已建立');
                isConnecting = false;
                reconnectAttempts = 0;

                if (onOpen && typeof onOpen === 'function') {
                    onOpen(event);
                }
            };

            // 连接错误
            eventSource.onerror = function (event) {
                console.error('SSE 连接错误:', event);
                isConnecting = false;

                if (onError && typeof onError === 'function') {
                    onError(event);
                }

                // 如果连接断开，尝试重连
                if (eventSource.readyState === EventSource.CLOSED) {
                    handleReconnect(url, onMessage, onError, onOpen);
                }
            };

        } catch (error) {
            console.error('创建 SSE 连接失败:', error);
            isConnecting = false;

            if (onError && typeof onError === 'function') {
                onError(error);
            }
        }
    }

    /**
     * 处理重连逻辑
     */
    function handleReconnect(url, onMessage, onError, onOpen) {
        if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
            console.error(`SSE 重连失败，已达到最大重试次数 (${MAX_RECONNECT_ATTEMPTS})`);
            return;
        }

        reconnectAttempts++;
        console.log(`SSE 连接断开，${RECONNECT_DELAY / 1000}秒后尝试第 ${reconnectAttempts} 次重连...`);

        // 清理旧连接
        disconnect();

        // 延迟重连
        reconnectTimer = setTimeout(() => {
            connect(url, onMessage, onError, onOpen);
        }, RECONNECT_DELAY);
    }

    /**
     * 断开 SSE 连接
     */
    function disconnect() {
        if (eventSource) {
            eventSource.close();
            eventSource = null;
        }

        if (reconnectTimer) {
            clearTimeout(reconnectTimer);
            reconnectTimer = null;
        }

        isConnecting = false;
        console.log('SSE 连接已断开');
    }

    /**
     * 检查连接状态
     * @returns {boolean} 是否已连接
     */
    function isConnected() {
        return eventSource && eventSource.readyState === EventSource.OPEN;
    }

    /**
     * 获取连接状态描述
     * @returns {string} 状态描述
     */
    function getConnectionState() {
        if (!eventSource) {
            return '未连接';
        }

        switch (eventSource.readyState) {
            case EventSource.CONNECTING:
                return '连接中';
            case EventSource.OPEN:
                return '已连接';
            case EventSource.CLOSED:
                return '已断开';
            default:
                return '未知状态';
        }
    }

    /**
     * 获取重连尝试次数
     * @returns {number} 重连次数
     */
    function getReconnectAttempts() {
        return reconnectAttempts;
    }

    // 公开 API
    return {
        connect: connect,
        disconnect: disconnect,
        isConnected: isConnected,
        getConnectionState: getConnectionState,
        getReconnectAttempts: getReconnectAttempts
    };
})();

// 导出模块
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SSEManager;
}