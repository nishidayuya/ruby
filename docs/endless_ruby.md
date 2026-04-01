# Endless Ruby (Indentation-based Block Termination)

## 概要
インデントレベルが浅く戻った際に、`end` キーワードがなくても自動的にブロックを終端するようにする。これにより、Pythonのようなインデントによる構造化が可能になる。

## 実装計画

### 1. 字句解析器 (Lexer, `parse.y`)

#### インデント情報の追跡
- `struct parser_params` の既存の `token_info` スタックを活用し、ブロックを開始するキーワード（`def`, `if`, `class`, `do` など）の基準インデントを記録する。
- `token_info_setup` が行頭からのインデント（タブとスペースの混在も考慮）を正しく計算していることを確認する。

#### 新しいトークンの導入
- `keyword_end` と同様の役割を持つ `tINDENT_END` トークンを新たに定義する。
- 既存の `tDUMNY_END` は、パースエラー（EOFでの未完了）用として残し、`tINDENT_END` は正常な構文として扱う。

#### 改行とインデントの監視
- `parser_yylex` が改行（`\n`）を処理する際、次に来る非空白・非コメントトークンのインデントを計測する。
- `token_info` スタックの最上位のインデント値よりも、新しいトークンのインデントが浅い場合、字句解析器は `tINDENT_END` を返す。
- 一度に複数のインデントレベルが戻る場合は、必要な回数だけ連続して `tINDENT_END` を返す必要がある。そのため、字句解析器に「未発行の `end` 待ち」の状態を持たせる。

### 2. 構文解析器 (Parser, `parse.y`)

#### 構文規則の更新
- `k_end` 規則を更新し、`keyword_end` または `tINDENT_END` のいずれかを受け入れるようにする。

```yacc
k_end           : keyword_end
                    {
                        token_info_pop(p, "end", &@$);
                        pop_end_expect_token_locations(p);
                    }
                | tINDENT_END
                    {
                        token_info_pop(p, "end", &@$);
                        pop_end_expect_token_locations(p);
                    }
                ;
```

### 3. 注意点と課題

- **行内ブロック**: `if condition then ... end` のように一行で完結している場合、インデントに基づく終端は行わないようにする（`nonspc` フラグの活用）。
- **継続行**: 演算子（`+`, `|` など）が末尾にある場合や、バックスラッシュによる継続行ではインデントを無視するように、Rubyの既存の継続行処理（`tIGNORED_NL`）と整合性をとる。
- **ヒアドキュメント**: インデント型ヒアドキュメント（`<<~`）との干渉を避ける。
- **既存コードへの影響**: 本機能をオプトイン（例：マジックコメント `# endless_ruby: true`）にするか、デフォルトで有効にするか検討が必要。

## 例

```ruby
def foo
  if true
    puts "in if"
  puts "out of if" # インデントが浅くなったため、if に対する end を自動挿入
puts "out of foo" # さらにインデントが浅くなったため、def に対する end を自動挿入
```

この記法により、Rubyの表現力を保ちつつ、`end` の記述を大幅に減らすことができる。
