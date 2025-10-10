class Foo
  def foo_method
    puts "foo"
    bar_method
  end

  def bar_method
    [1, 2, 3].map { |x| x * 2 }
  end
end
