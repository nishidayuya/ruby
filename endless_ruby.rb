# endless_ruby: true
class Foo
  def bar
    p([__FILE__, __LINE__])
    if true
      p([__FILE__, __LINE__])
    else
      p([__FILE__, __LINE__])
    p([__FILE__, __LINE__])

Foo.new.bar
if false
  p([__FILE__, __LINE__])
else
  p([__FILE__, __LINE__])
