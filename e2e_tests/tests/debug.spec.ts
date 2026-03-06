import { test, expect } from '@playwright/test';

test('Dump DOM structure', async ({ page }) => {
  await page.goto('/?enable-semantics=true');
  
  // Flutterの起動を待つ（少し長めに）
  await page.waitForTimeout(10000);
  
  // 現在のHTML構造をすべて出力
  const content = await page.content();
  console.log('--- DEBUG: HTML CONTENT START ---');
  console.log(content);
  console.log('--- DEBUG: HTML CONTENT END ---');
  
  // 画面中央をクリックした後の構造も確認
  await page.mouse.click(400, 300);
  await page.waitForTimeout(2000);
  const contentAfterClick = await page.content();
  console.log('--- DEBUG: AFTER CLICK CONTENT START ---');
  console.log(contentAfterClick);
  console.log('--- DEBUG: AFTER CLICK CONTENT END ---');
});
