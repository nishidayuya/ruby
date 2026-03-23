# frozen-literal-magic-comment 技術設計文書

**作成日**: 2024-05-16
**ステータス**: ドラフト
**関連要件**: [requirements.md](requirements.md)

## 1. 目的

マジックコメント `# frozen_literal: true` を導入し、Rubyソースコード内の文字列、配列、ハッシュリテラルをデフォルトで不変（frozen）にするための技術設計。

## 2. 構造体の変更

### 2.1 `rb_ast_body_t` (node.h / rubyparser.h)
AST本体に `frozen_literal` フラグを保持するフィールドを追加する。

```c
typedef struct rb_ast_body_struct {
    // ... 既存のフィールド
    signed int frozen_string_literal:2;
    signed int frozen_literal:2; /* 追加: -1: 未指定, 0: false, 1: true */
    // ...
} rb_ast_body_t;
```

### 2.2 `rb_iseq_compile_data_options` (iseq.h)
コンパイラオプションにフラグを追加し、ASTから引き継げるようにする。

```c
struct rb_iseq_compile_data_options {
    // ...
    signed int frozen_string_literal: 2;
    signed int frozen_literal: 2; /* 追加 */
    // ...
};
```

## 3. パーサの変更 (parse.y)

### 3.1 マジックコメントの認識
`magic_comments` テーブルに `frozen_literal` を追加する。

```c
static const struct magic_comment magic_comments[] = {
    // ...
    {"frozen_string_literal", parser_set_frozen_string_literal},
    {"frozen_literal", parser_set_frozen_literal}, /* 追加 */
    // ...
};
```

### 3.2 セッターの実装
`parser_set_frozen_literal` を実装し、`frozen_literal` が `true` の場合は `frozen_string_literal` も `true` として扱うロジックを組み込む。

```c
static void
parser_set_frozen_literal(struct parser_params *p, const char *name, const char *val)
{
    int b = parser_get_bool(p, name, val);
    if (b >= 0) {
        p->frozen_literal = b;
        if (b == 1) p->frozen_string_literal = 1; // frozen_literal: true なら string も true
    }
}
```

## 4. コンパイラの変更 (compile.c)

### 4.1 `compile_array`
`frozen_literal` が有効な場合、配列リテラルの生成後にフリーズ処理を行う。

- **静的リテラルのみの場合**: 既存の `duparray`（非表示配列の複製）ではなく、フリーズ済みの非表示配列を直接 `putobject` する、または `duparray` の後に `opt_ary_freeze` を発行する。
- **動的要素を含む場合**: `newarray` 命令の後に `opt_ary_freeze` を発行する。

### 4.2 `compile_hash`
配列と同様に、ハッシュリテラル生成後に `opt_hash_freeze` を発行する。

## 5. Prism パーサへの対応 (prism/)

`prism/prism.c` のマジックコメント解析部 (`pm_parser_magic_comment`) に `frozen_literal` の処理を追加し、`pm_options_t` を通じてコンパイラに伝える。

## 6. 考慮事項

- **優先順位**: `# frozen_literal: true` と `# frozen_string_literal: false` が混在した場合、後から書かれたマジックコメントが優先される既存の挙動を維持する。
- **パフォーマンス**: `opt_ary_freeze` は実行時に要素をチェックせず、コンパイル時にフリーズ済みであることを保証するため、オーバーヘッドは最小限に抑えられる。
