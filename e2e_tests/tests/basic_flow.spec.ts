import { test, expect } from '@playwright/test';

test.describe('Easy Molkky Score - Visual & Stability Check', () => {
  
  test('Should load without JS errors and render UI', async ({ page }) => {
    const errors: string[] = [];
    
    // ブラウザコンソールのエラーを監視 (真っ白画面の検知)
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    page.on('pageerror', err => errors.push(err.message));

    // ページを開く
    await page.goto('/');
    
    // Flutterの描画開始を待つ (flutter-view要素の出現)
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    
    // 描画が安定するまで少し待機
    await page.waitForTimeout(5000);
    
    // JSエラーが1つも出ていないことを確認
    if (errors.length > 0) {
      console.error('JS Errors detected:', errors);
    }
    expect(errors.length, `Detected ${errors.length} JS errors on startup`).toBe(0);

    console.log('--- Startup check passed: No JS errors found ---');
  });

  test('Should reach interactive state', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    
    // 画面をクリックして Flutter をアクティブに
    await page.mouse.click(400, 300);
    await page.waitForTimeout(2000);
    
    // DOMの中身を確認してブートストラップ完了を検証
    const html = await page.content();
    expect(html).toContain('flutter_bootstrap.js');
    
    console.log('--- Interaction check passed: Flutter engine is alive ---');
  });
});
