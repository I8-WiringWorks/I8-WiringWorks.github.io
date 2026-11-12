document.addEventListener('DOMContentLoaded', () => {
  // コピーボタンを「非表示」にしたい言語クラスのリスト
  const ignoreLanguages = ['language-plaintext', 'language-text', 'language-console', 'language-output'];

  const codeBlocks = document.querySelectorAll('.markdown-body pre, .highlighter-rouge pre');

  codeBlocks.forEach((pre) => {
    // 自身または親要素に .no-copy が指定されていたらスキップ
    if (pre.closest('.no-copy')) {
      return;
    }

    // pre自身または親要素（div.language-xxx）のクラスを取得
    const highlightContainer = pre.closest('[class*="language-"]') || pre;
    const classList = Array.from(highlightContainer.classList);

    // 除外リストに該当する、または言語クラスが一切ない場合はスキップ
    const isIgnored = ignoreLanguages.some((cls) => classList.includes(cls));
    const hasNoLanguage = !classList.some((cls) => cls.startsWith('language-'));

    if (isIgnored || hasNoLanguage) {
      return; // コピーボタンを作らずに次のブロックへ
    }

    // preの親要素、またはpre自体を相対配置のコンテナとして扱う
    const container = pre.parentElement;
    if (!container.classList.contains('code-block-wrapper')) {
      const wrapper = document.createElement('div');
      wrapper.className = 'code-block-wrapper';
      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(pre);
    }

    // コピーボタンの生成
    const button = document.createElement('button');
    button.className = 'copy-code-button';
    button.type = 'button';
    button.setAttribute('aria-label', 'コードをコピー');
    button.innerHTML = `
      <svg class="copy-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
        <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
      </svg>
      <span class="copy-text">Copy</span>
    `;

    button.addEventListener('click', async () => {
      const codeElement = pre.querySelector('code') || pre;
      const textToCopy = codeElement.innerText;

      try {
        await navigator.clipboard.writeText(textToCopy);
        button.classList.add('copied');
        button.querySelector('.copy-text').textContent = 'Copied!';

        setTimeout(() => {
          button.classList.remove('copied');
          button.querySelector('.copy-text').textContent = 'Copy';
        }, 2000);
      } catch (err) {
        console.error('クリップボードへのコピーに失敗しました:', err);
      }
    });

    pre.parentElement.appendChild(button);
  });
});
