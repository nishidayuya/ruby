# frozen_literal: false
require 'test/unit'

class TestFrozenLiteralFalse < Test::Unit::TestCase
  def test_string_not_frozen
    assert !"string".frozen?
  end

  def test_array_not_frozen
    assert ![1, 2, 3].frozen?
  end

  def test_hash_not_frozen
    assert !{a: 1}.frozen?
  end
end
