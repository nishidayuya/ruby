# Endless Rubyをマジックコメントなしで動作させるための実装計画

## 概要
現在、Endless Ruby機能（インデントベースのブロック終端）はマジックコメント `# endless_ruby: true` を記述することで有効になります。
本計画では、マジックコメントによる指定なしでこの機能をデフォルトで有効にし、`endless_ruby.rb` がそのまま動作するようにします。
後方互換性は考慮しません。

## 実装手順

### 1. `parse.y` (yaccパーサ) のデフォルト値変更
`parse.y` におけるパーサ初期化ルーチンで `endless_ruby` フラグをデフォルトで `1` に設定します。

- **対象ファイル**: `parse.y`
- **変更箇所**: `parser_initialize` 関数
- **内容**:
  ```c
  static void
  parser_initialize(struct parser_params *p)
  {
      /* ... */
      p->frozen_string_literal = -1; /* not specified */
      p->endless_ruby = 1;           /* デフォルトで有効化 */
      p->token_info_enabled = 1;     /* Endless Rubyの動作に必要 */
  ```

### 2. `prism` パーサのデフォルト値変更
Prismパーサでも同様にデフォルトで機能を有効にします。

- **対象ファイル**: `prism/prism.c`
- **変更箇所**: `pm_parser_init` 内の `pm_parser_t` 初期化部分
- **内容**:
  ```c
  pm_parser_t parser = {
      /* ... */
      .warn_mismatched_indentation = true,
      .endless_ruby = true, /* デフォルトで有効化 */
      .pending_ends = 0,
      /* ... */
  };
  ```

### 3. `ruby.c` のパーサ自動切り替えロジックの削除
現在、`ruby.c` ではマジックコメントを検知してパーサを強制的に `parse.y` に切り替える処理がありますが、これを削除します。これにより、`--parser=prism` を指定した場合でもEndless RubyがPrismで動作するようになります。

- **対象ファイル**: `ruby.c`
- **変更箇所**: `process_options` 関数内
- **内容**:
  ```c
  // 以下のブロックを削除またはコメントアウト
  // if (rb_ruby_prism_p() && !opt->e_script && is_endless_ruby_file(opt->script_name)) {
  //     rb_ruby_default_parser_set(RB_DEFAULT_PARSER_PARSE_Y);
  // }
  ```
  また、不要になった `is_endless_ruby_file` 関数自体も削除します。

### 4. 動作確認
- `endless_ruby.rb` からマジックコメントを削除し、正常に動作することを確認します。
- `miniruby` を用いて既存のテスト（特にパーサ関連）を実行し、影響範囲を確認します。

## 懸念点・備考
- インデントが不正な既存のRubyコードが動作しなくなる可能性がありますが、今回は後方互換性を無視する方針に基づき、これを許容します。
- Endless Rubyが完全に全てのRuby機能に対して安定しているか、特にPrism実装側での挙動を確認する必要があります。
