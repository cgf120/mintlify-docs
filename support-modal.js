// 联系支持弹框功能
(function() {
    'use strict';

    // 等待 DOM 加载完成
    function initSupportModal() {
        // 添加弹框关闭事件监听
        setupModalEvents();

        // 处理可能存在的 href="#" 链接
        setTimeout(function() {
            const hashLinks = document.querySelectorAll('a[href="#"]');
            hashLinks.forEach(function(link) {
                if (link.textContent.includes('联系支持')) {
                    link.addEventListener('click', function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        showSupportModal();
                    });
                }
            });
        }, 500);
    }
    
    // 检测并应用主题
    function applyThemeToModal() {
        const modal = document.getElementById('support-modal');
        if (!modal) return;

        // 检测当前主题
        const isDark = document.documentElement.getAttribute('data-theme') === 'dark' ||
                      document.documentElement.classList.contains('dark') ||
                      document.body.classList.contains('dark') ||
                      window.matchMedia('(prefers-color-scheme: dark)').matches;

        if (isDark) {
            modal.classList.add('dark');
        } else {
            modal.classList.remove('dark');
        }
    }

    // 显示支持弹框 - 设为全局函数
    window.showSupportModal = function() {
        console.log('尝试显示支持弹框'); // 调试信息
        const modal = document.getElementById('support-modal');
        if (modal) {
            console.log('找到弹框元素，正在显示'); // 调试信息
            applyThemeToModal(); // 应用主题
            modal.classList.add('show');
            document.body.style.overflow = 'hidden'; // 防止背景滚动
        } else {
            console.log('未找到弹框元素'); // 调试信息
        }
    };
    
    // 隐藏支持弹框
    function hideSupportModal() {
        const modal = document.getElementById('support-modal');
        if (modal) {
            modal.classList.remove('show');
            document.body.style.overflow = ''; // 恢复滚动
        }
    }
    
    // 设置弹框事件监听
    function setupModalEvents() {
        // 点击关闭按钮
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('close-button') || 
                e.target.classList.contains('close-icon')) {
                hideSupportModal();
            }
        });
        
        // 点击弹框背景关闭
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('support-modal')) {
                hideSupportModal();
            }
        });
        
        // ESC 键关闭弹框
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                hideSupportModal();
            }
        });
    }
    
    // 页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initSupportModal);
    } else {
        initSupportModal();
    }
    
    // 处理单页应用的路由变化
    let lastUrl = location.href;
    new MutationObserver(() => {
        const url = location.href;
        if (url !== lastUrl) {
            lastUrl = url;
            // 延迟执行，确保新页面内容已加载
            setTimeout(initSupportModal, 100);
        }
    }).observe(document, { subtree: true, childList: true });
    
})();
