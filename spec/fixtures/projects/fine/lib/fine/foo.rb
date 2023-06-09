module Fine
  class Foo
    def initialize(a:)
      @a = a
    end

    def a
      @a
    end

    def a_times(n)
      a * n
    end
  end
end
