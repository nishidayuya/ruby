# Implementation Plan: Endless Ruby support in Prism Parser

## Overview
"Endless Ruby" is a proposed extension to Ruby syntax where indentation levels are used to determine block boundaries, reducing the need for explicit `end` keywords. This document outlines the plan to implement this feature in the Prism parser.

## Core Logic
A block that usually requires an `end` keyword will be automatically terminated if a subsequent line starts with a token that has an indentation level less than or equal to the indentation level of the keyword that started the block.

### Exceptions
Continuation keywords such as `else`, `elsif`, `rescue`, `ensure`, `when`, and `in` do not terminate the block if they are at the same indentation level as the opening keyword.

## Proposed Changes

### 1. Parser State (`pm_parser_t`)
Add the following fields to the `pm_parser` struct in `prism/parser.h`:
- `bool endless_ruby`: A flag indicating if Endless Ruby mode is enabled (via magic comment).
- `uint32_t pending_ends`: A counter for the number of `TOKEN_KEYWORD_END` tokens that the lexer needs to inject.

### 2. Context Node (`pm_context_node_t`)
Add a field to track the indentation level of the context:
- `int64_t indent`: The column (respecting tab stops) where the block-starting keyword appeared. A value of `-1` indicates the context does not support indentation-based termination.

### 3. Magic Comment Detection
Update `parser_lex_magic_comment` in `prism/prism.c` to recognize `# endless_ruby: true` and set `parser->endless_ruby = true`.

### 4. Context Management
Update `context_push` in `prism/prism.c` to record the indentation level.
- When pushing a context that supports Endless Ruby (e.g., `PM_CONTEXT_IF`, `PM_CONTEXT_DEF`), calculate the column of the current token using `token_column()`.
- Store this value in `context_node->indent`.

### 5. Lexer Injection (`parser_lex`)
Modify the newline handling in `parser_lex` (within `prism.c`):
- When a newline is encountered and `parser->endless_ruby` is true:
    1. Peek ahead to the next non-blank, non-comment token.
    2. Calculate its indentation level (`next_indent`).
    3. Identify the next token type.
    4. While `parser->current_context->indent >= next_indent` and the next token is NOT a continuation keyword:
        - Increment `parser->pending_ends`.
        - Pop the context.
- At the start of `parser_lex`, if `parser->pending_ends > 0`:
    - Decrement `parser->pending_ends`.
    - Set `parser->current.type = PM_TOKEN_KEYWORD_END`.
    - Return from the lexer.

### 6. Continuation Keywords
The following tokens should be treated as continuations and should NOT trigger a block termination at the same indentation level:
- `PM_TOKEN_KEYWORD_ELSE`
- `PM_TOKEN_KEYWORD_ELSIF`
- `PM_TOKEN_KEYWORD_RESCUE`
- `PM_TOKEN_KEYWORD_ENSURE`
- `PM_TOKEN_KEYWORD_WHEN`
- `PM_TOKEN_KEYWORD_IN` (in the context of a `case` statement)

### 7. EOF Handling
When the end of the file is reached, if `parser->endless_ruby` is true, the lexer should inject `TOKEN_KEYWORD_END` for all remaining indentation-based contexts before finally returning `TOKEN_EOF`.

## Implementation Steps
1.  Modify `prism/parser.h` to add the necessary fields to `pm_parser_t` and `pm_context_node_t`.
2.  Implement magic comment parsing for `endless_ruby`.
3.  Update `context_push` to capture indentation.
4.  Modify `parser_lex` to handle token injection based on indentation back-off.
5.  Test with `endless_ruby.rb` and ensure it parses correctly.

## Considerations
- **Tab Handling**: Use `token_column` which already handles tab expansion (to 8 spaces by default, matching Ruby's behavior).
- **Blank Lines**: Lines containing only whitespace or comments should be ignored when determining the "next indentation".
- **Heredocs**: Ensure indentation-based termination doesn't interfere with heredoc content.
- **Error Recovery**: The parser should still work correctly if explicit `end` keywords are used alongside indentation-based termination.
