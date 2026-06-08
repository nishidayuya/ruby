# frozen_literal: true

o = {
  foo: [
    "baz",
  ],
}

pp(
  hash: o.frozen?,
  array: o[:foo].frozen?,
  string: o[:foo][0].frozen?,
)
