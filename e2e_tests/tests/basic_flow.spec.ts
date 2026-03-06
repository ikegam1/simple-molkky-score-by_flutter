import { test, expect } from '@playwright/test';

test.describe('Easy Molkky Score - Localization & Basic Flow', () => {
  
  test('Should display in Japanese by default in ja-JP locale', async ({ page }) => {
    // セマンティクスを有効にして起動
    await page.goto('/?enable-semantics=true');
    
    // タイトルの存在確認 (セマンティクス経由)
    await expect(page.getByLabel('Easy Molkky Score')).toBeVisible({ timeout: 60000 });
    
    // 日本語であることを確認
    await expect(page.getByLabel('プレイヤー名')).toBeVisible();
    await expect(page.getByLabel('ゲーム開始')).toBeVisible();
  });

  test('Should switch to English when clicking language button', async ({ page }) => {
    await page.goto('/?enable-semantics=true');
    await expect(page.getByLabel('Easy Molkky Score')).toBeVisible({ timeout: 60000 });
    
    // 言語切り替えボタン (JA/EN) をクリック
    // FlutterのTextButtonはaria-labelになる
    const enButton = page.getByRole('button', { name: 'EN' });
    await enButton.click();
    
    // 英語表示に切り替わったことを確認
    await expect(page.getByLabel('Player Name')).toBeVisible();
    await expect(page.getByLabel('Start Game')).toBeVisible();
  });

  test('Should start game and enter score without blank screen', async ({ page }) => {
    await page.goto('/?enable-semantics=true');
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
    await expect(page.getByLabel('第 1 セット')).toBeVisible();
    await expect(page.getByLabel('Player 1 の番 (ターン 1)')).toBeVisible();

    // スコア入力 (スキトル 10 を選択)
    await page.getByLabel('10', { exact: true }).click();
    await page.getByLabel('決定 (10点)').click();

    // 次のターンに進んでいることを確認
    await expect(page.getByLabel('Player 1 の番 (ターン 2)')).toBeVisible();
  });
});
