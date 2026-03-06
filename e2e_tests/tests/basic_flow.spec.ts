import { test, expect } from '@playwright/test';

test.describe('Easy Molkky Score - Localization & Basic Flow', () => {
  
  test.beforeEach(async ({ page }) => {
    // セマンティクスを強制有効にしてページを開く
    await page.goto('/?enable-semantics=true');
    
    // Flutter Webの特性：描画完了後に一度画面をクリックするとセマンティクス要素が生成される
    // 画面中央を適当にクリックしてアクティベートを促す
    await page.mouse.click(400, 300);
    
    // アプリがロードされるまで十分に待つ
    await page.waitForLoadState('networkidle');
  });

  test('Should display in Japanese by default in ja-JP locale', async ({ page }) => {
    // ラベルが表示されるまで最大60秒待機
    const title = page.getByLabel('Easy Molkky Score');
    await expect(title).toBeVisible({ timeout: 60000 });
    
    // 日本語であることを確認
    await expect(page.getByLabel('プレイヤー名')).toBeVisible();
    await expect(page.getByLabel('ゲーム開始')).toBeVisible();
  });

  test('Should switch to English when clicking language button', async ({ page }) => {
    await expect(page.getByLabel('Easy Molkky Score')).toBeVisible({ timeout: 60000 });
    
    // 言語切り替えボタン (JA/EN) をクリック
    // セマンティクスツリーでは TextButton のラベルがそのまま role="button" になる
    const enButton = page.getByRole('button', { name: 'EN' });
    await enButton.click();
    
    // 英語表示に切り替わったことを確認
    await expect(page.getByLabel('Player Name')).toBeVisible();
    await expect(page.getByLabel('Start Game')).toBeVisible();
  });

  test('Should start game and enter score without blank screen', async ({ page }) => {
    await expect(page.getByLabel('Easy Molkky Score')).toBeVisible({ timeout: 60000 });
    
    // プレイヤーの追加
    const input = page.getByRole('textbox');
    await input.fill('Player 1');
    await page.keyboard.press('Enter');
    
    // リストに追加されたことを確認
    await expect(page.getByLabel('1. Player 1')).toBeVisible();

    // ゲーム開始
    await page.getByLabel('ゲーム開始').click();

    // ゲーム画面が表示されていることを確認
    await expect(page.getByLabel('第 1 セット')).toBeVisible({ timeout: 10000 });
    await expect(page.getByLabel(/Player 1 の番/)).toBeVisible();

    // スコア入力 (スキトル 10 を選択)
    await page.getByLabel('10', { exact: true }).click();
    await page.getByLabel(/決定/).click();

    // 次のターンに進んでいることを確認
    await expect(page.getByLabel(/ターン 2/)).toBeVisible();
  });
});
