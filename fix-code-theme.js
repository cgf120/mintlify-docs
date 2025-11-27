// 代码块主题修复脚本
(function() {
    'use strict';
    
    // 修复代码块样式的函数
    function fixCodeBlockStyles() {
        const theme = document.documentElement.getAttribute('data-theme') || 
                     document.body.getAttribute('data-theme') ||
                     (document.body.classList.contains('light') ? 'light' : 'dark');
        
        if (theme === 'light') {
            // 获取所有代码相关元素
            const codeElements = document.querySelectorAll('pre, code, .highlight, .code-block, [class*="language-"]');
            
            codeElements.forEach(element => {
                // 强制设置样式 - 简洁版本，无边框
                element.style.setProperty('color', '#24292f', 'important');
                element.style.setProperty('background-color', '#f6f8fa', 'important');
                element.style.setProperty('border', 'none', 'important');
                element.style.setProperty('border-radius', '6px', 'important');

                // 修复子元素
                const childElements = element.querySelectorAll('*');
                childElements.forEach(child => {
                    // 不修改 token 类的元素，保持语法高亮
                    if (!child.classList.contains('token')) {
                        child.style.setProperty('color', '#24292f', 'important');
                    }
                });
            });
            
            // 特别处理可能的白色文本
            const whiteTextElements = document.querySelectorAll('[style*="color: white"], [style*="color: #fff"], [style*="color: #ffffff"]');
            whiteTextElements.forEach(element => {
                if (element.closest('pre, code, .highlight, .code-block')) {
                    element.style.setProperty('color', '#24292f', 'important');
                }
            });
        }
    }
    
    // 监听主题变化
    function observeThemeChanges() {
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'attributes' && 
                    (mutation.attributeName === 'data-theme' || mutation.attributeName === 'class')) {
                    setTimeout(fixCodeBlockStyles, 100);
                }
            });
        });
        
        // 观察 html 和 body 元素的属性变化
        observer.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ['data-theme', 'class']
        });
        
        observer.observe(document.body, {
            attributes: true,
            attributeFilter: ['data-theme', 'class']
        });
    }
    
    // 监听 DOM 变化，处理动态加载的代码块
    function observeContentChanges() {
        const observer = new MutationObserver(function(mutations) {
            let hasNewCodeBlocks = false;
            mutations.forEach(function(mutation) {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) { // Element node
                            if (node.matches && (node.matches('pre, code, .highlight, .code-block') || 
                                node.querySelector('pre, code, .highlight, .code-block'))) {
                                hasNewCodeBlocks = true;
                            }
                        }
                    });
                }
            });
            
            if (hasNewCodeBlocks) {
                setTimeout(fixCodeBlockStyles, 100);
            }
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
    
    // 初始化
    function init() {
        // 立即修复
        fixCodeBlockStyles();
        
        // 设置观察器
        observeThemeChanges();
        observeContentChanges();
        
        // 页面加载完成后再次修复
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', fixCodeBlockStyles);
        }
        
        // 窗口加载完成后再次修复
        window.addEventListener('load', fixCodeBlockStyles);
        
        // 定期检查（作为最后的保障）
        setInterval(fixCodeBlockStyles, 2000);
    }
    
    // 启动脚本
    init();
    
    // 暴露全局函数供手动调用
    window.fixCodeBlockStyles = fixCodeBlockStyles;
    
})();
