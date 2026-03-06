import { test, expect } from '@playwright/test';

test.describe('Easy Molkky Score - Localization & Basic Flow', () => {
  
  test.beforeEach(async ({ page }) => {
    // セマンティクスを強制有効にしてページを開く
    await page.goto('/?enable-semantics=true');
    
    // アプリが完全にロードされるのを待つ (flt-glass要素の存在を確認)
    await page.waitForSelector('flt-glass', { timeout: 30000 });
    
    // 画面中央をクリックしてセマンティクスをアクティベート
    await page.mouse.click(400, 300);
  });

  test('Should display in Japanese by default in ja-JP locale', async ({ page }) => {
    // 日本語のラベルが表示されるまで待機
    await page.waitForSelector('[aria-label*="Easy Molkky Score"]', { timeout: 30000 });
    
    // 日本語であることを確認
    await expect(page.getByLabel('プレイヤー名')).toBeVisible();
    await expect(page.getByLabel('ゲーム開始')).toBeVisible();
  });

  test('Should switch to English when clicking language button', async ({ page }) => {
    await page.waitForSelector('[aria-label*="Easy Molkky Score"]', { timeout: 30000 });
    
    // 言語切り替えボタン (EN) をクリック
    const enButton = page.getByRole('button', { name: 'EN' });
    await enButton.click();
    
    // 英語表示に切り替わったことを確認
    await expect(page.getByLabel('Player Name')).toBeVisible();
    await expect(page.getByLabel('Start Game')).toBeVisible();
  });

  test('Should start game and enter score without blank screen', async ({ page }) => {
    await page.waitForSelector('[aria-label*="Easy Molkky Score"]', { timeout: 30000 });
    
    // プレイヤーの追加
    const input = page.getByRole('textbox');
    await input.fill('Player 1');
    await page.keyboard.press('Enter');
    
    // リストに追加されたことを確認
    await expect(page.getByLabel('1. Player 1')).toBeVisible();

    // ゲーム開始
    await page.getByLabel('ゲーム開始').click();

    // ゲーム画面の表示確認
    await expect(page.getByLabel('第 1 セット')).toBeVisible({ timeout: 10000 });
    
    // 10点入力
    await page.getByLabel('10', { exact: true }).click();
    await page.getByLabel(/決定/).click();

    // 次のターン確認
    await expect(page.getByLabel(/ターン 2/)).toBeVisible();
  });
});
