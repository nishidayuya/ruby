# frozen-literal-magic-comment コンテキストノート

## プロジェクト概要
Rubyのパーサおよびコンパイラに新しいマジックコメントを追加する。

## 技術スタック
- **Language**: C (Ruby Core)
- **Parser**: Bison (`parse.y`), Prism (`prism/`)
- **Compiler**: `compile.c`
- **VM**: YARV

## 開発ルール
- 既存の `frozen_string_literal` の実装パターンを遵守する。
- 性能劣化を招かないよう、コンパイル時最適化を活用する。

## 関連実装
- `parse.y`: `magic_comments` テーブル
- `iseq.h`: `struct rb_iseq_compile_data_options`
- `compile.c`: `iseq_optimize_insn`

## 注意事項
- `frozen_literal: true` は `frozen_string_literal: true` のスーパーセットとして機能させる必要がある。
- Prismパーサへの対応も将来的に必要になる可能性がある。
