# frozen_literal: true
require 'test/unit'

class TestFrozenLiteral < Test::Unit::TestCase
  def test_string_frozen
    assert "string".frozen?
  end

  def test_array_frozen
    assert [1, 2, 3].frozen?
  end

  def test_hash_frozen
    assert({a: 1}.frozen?)
  end

  def test_dynamic_array_frozen
    a = 1
    assert [a, 2].frozen?
  end

  def test_dynamic_hash_frozen
    a = 1
    assert({a: a}.frozen?)
  end
end
