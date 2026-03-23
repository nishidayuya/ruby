# マジックコメント frozen_literal: true の導入計画

## 概要
マジックコメント `# frozen_literal: true` を導入し、文字列・配列・ハッシュのすべてのリテラルをデフォルトで不変（frozen）にします。

詳細な要件定義書は以下を参照してください：
- [要件定義書 (requirements.md)](spec/frozen-literal-magic-comment/requirements.md)
- [ヒアリング記録 (interview-record.md)](spec/frozen-literal-magic-comment/interview-record.md)
- [準備タスク (prep.md)](spec/frozen-literal-magic-comment/prep.md)

## 実装方針（技術要約）
1. **Parser (`parse.y`)**: 
   `magic_comments` テーブルに `"frozen_literal"` を追加し、セッターを実装する。
2. **Compile Options (`iseq.h`, `compile.c`)**:
   `frozen_literal` フラグをコンパイラオプションに追加する。
3. **Compiler (`compile.c`)**:
   配列・ハッシュリテラルのコンパイル時に、`frozen_literal` フラグが有効であれば `opt_ary_freeze` / `opt_hash_freeze` 等の最適化命令を生成する。
4. **Integration**:
   `frozen_literal: true` は `frozen_string_literal: true` を包含する挙動とする。
