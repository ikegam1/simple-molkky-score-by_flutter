import { test, expect } from '@playwright/test';

// 日本語環境でのテスト
test.use({ locale: 'ja-JP' });

test.describe('Easy Molkky Score - Localization & Basic Flow', () => {
  
  test('Should display in Japanese by default in ja-JP locale', async ({ page }) => {
    // ローカルでのテスト時は flutter run -d web-server --web-port 8080 等で起動している前提
    await page.goto('http://localhost:8080/');
    
    // トップ画面のタイトル確認
    await expect(page.locator('body')).toContainText('Easy Molkky Score');
    // 日本語であることを確認
    await expect(page.locator('body')).toContainText('プレイヤー名');
    await expect(page.locator('body')).toContainText('ゲーム開始');
  });

  test('Should switch to English when clicking language button', async ({ page }) => {
    await page.goto('http://localhost:8080/');
    
    // 言語切り替えボタン (EN) をクリック
    // FlutterのWebはCanvas描画だが、セマンティクスラベルがテキストとして出力される
    await page.getByText('EN').click();
    
    // 英語表示に切り替わったことを確認
    await expect(page.locator('body')).toContainText('Player Name');
    await expect(page.locator('body')).toContainText('Start Game');
  });

  test('Should start game and enter score without blank screen', async ({ page }) => {
    await page.goto('http://localhost:8080/');
    
    // プレイヤーの追加
    const input = page.getByLabel('プレイヤー名');
    await input.fill('Player 1');
    await page.keyboard.press('Enter');
    
    await expect(page.locator('body')).toContainText('1. Player 1');

    // ゲーム開始
    await page.getByText('ゲーム開始').click();

    // ゲーム画面が表示されていることを確認（真っ白になっていない）
    await expect(page.locator('body')).toContainText('第 1 セット');
    await expect(page.locator('body')).toContainText('Player 1 の番');

    // スコア入力 (スキトル 10 を選択)
    await page.getByText('10', { exact: true }).click();
    await page.getByText('決定').click();

    // 次のターンに進んでいることを確認
    await expect(page.locator('body')).toContainText('ターン 2');
  });
});
