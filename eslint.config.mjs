import js from '@eslint/js';
import globals from 'globals';
import { defineConfig } from 'eslint/config';

export default defineConfig([
  {
    files: ['**/*.{js,mjs,cjs}'],
    plugins: { js },
    extends: ['js/recommended'],
    languageOptions: {
      globals: globals.browser,
    },
    rules: {
      // ========================================
      // コード品質に関するルール（自動修正可能）
      // ========================================

      // 再代入しない変数は const に（自動修正可能）
      'prefer-const': 'error',

      // var を使用しない（自動修正可能）
      'no-var': 'error',

      // オブジェクトの省略記法を使用（自動修正可能）
      'object-shorthand': 'error',

      // アロー関数の省略形を使用（自動修正可能）
      'arrow-body-style': ['error', 'as-needed'],

      // テンプレートリテラルを使用（自動修正可能）
      'prefer-template': 'error',

      // ========================================
      // フォーマット関連のルール（自動修正可能）
      // ========================================

      // セミコロンを必須に（自動修正可能）
      'semi': ['error', 'always'],

      // シングルクォートに統一（自動修正可能）
      'quotes': ['error', 'single', { avoidEscape: true }],

      // インデントは2スペース（自動修正可能）
      'indent': ['error', 2, { SwitchCase: 1 }],

      // 末尾カンマを追加（自動修正可能）
      'comma-dangle': ['error', 'always-multiline'],

      // 余分なスペースを削除（自動修正可能）
      'no-multi-spaces': 'error',

      // ファイル末尾に改行を追加（自動修正可能）
      'eol-last': ['error', 'always'],

      // 空行は最大1行（自動修正可能）
      'no-multiple-empty-lines': ['error', { max: 1, maxEOF: 0 }],

      // オブジェクトのキーと値の間にスペース（自動修正可能）
      'key-spacing': ['error', { beforeColon: false, afterColon: true }],

      // カンマの後にスペース（自動修正可能）
      'comma-spacing': ['error', { before: false, after: true }],

      // 演算子の前後にスペース（自動修正可能）
      'space-infix-ops': 'error',

      // キーワードの前後にスペース（自動修正可能）
      'keyword-spacing': ['error', { before: true, after: true }],

      // 関数の括弧の前にスペース（自動修正可能）
      'space-before-function-paren': ['error', {
        anonymous: 'always',
        named: 'never',
        asyncArrow: 'always',
      }],

      // ブロックの前にスペース（自動修正可能）
      'space-before-blocks': 'error',

      // オブジェクトの波括弧の間にスペース（自動修正可能）
      'object-curly-spacing': ['error', 'always'],

      // 配列の角括弧の間にスペースを入れない（自動修正可能）
      'array-bracket-spacing': ['error', 'never'],

      // 行末の空白を削除（自動修正可能）
      'no-trailing-spaces': 'error',
    },
  },
]);
