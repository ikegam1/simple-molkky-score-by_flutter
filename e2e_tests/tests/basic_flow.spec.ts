import { test, expect } from '@playwright/test';

test.describe('Easy Molkky Score - Localization & Basic Flow', () => {
  
  test('Should display in Japanese by default in ja-JP locale', async ({ page }) => {
    // 日本語環境をシミュレート
    await page.context().addCookies([]);
    await page.goto('/');
    
    // Flutterアプリの起動待ち（何らかのテキストが出るまで）
    await expect(page.getByText('Easy Molkky Score')).toBeVisible({ timeout: 30000 });
    
    // 日本語であることを確認
    await expect(page.getByText('プレイヤー名')).toBeVisible();
    await expect(page.getByText('ゲーム開始')).toBeVisible();
  });

  test('Should switch to English when clicking language button', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByText('Easy Molkky Score')).toBeVisible({ timeout: 30000 });
    
    // 言語切り替えボタン (EN) をクリック
    // HTMLレンダラーではテキストとして取得可能
    const enButton = page.getByText('EN', { exact: true });
    await enButton.click();
    
    // 英語表示に切り替わったことを確認
    await expect(page.getByText('Player Name')).toBeVisible();
    await expect(page.getByText('Start Game')).toBeVisible();
  });

  test('Should start game and enter score without blank screen', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByText('Easy Molkky Score')).toBeVisible({ timeout: 30000 });
    
    // プレイヤーの追加
    // ラベルではなくプレースホルダーやテキストで探す方がFlutter Webでは安定する
    const input = page.locator('input[type="text"]').first();
    await input.fill('Player 1');
    await page.keyboard.press('Enter');
    
    await expect(page.getByText('1. Player 1')).toBeVisible();

    // ゲーム開始
    await page.getByText('ゲーム開始').click();

    // ゲーム画面が表示されていることを確認（真っ白になっていない）
    await expect(page.getByText('第 1 セット')).toBeVisible();
    await expect(page.getByText('Player 1 の番')).toBeVisible();

    // スコア入力 (スキトル 10 を選択)
    await page.getByText('10', { exact: true }).click();
    await page.getByText('決定').click();

    // 次のターンに進んでいることを確認
    await expect(page.getByText('ターン 2')).toBeVisible();
  });
});
