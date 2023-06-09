module Fine
  class Bar
    def initialize
      @a = @b = nil
    end

    attr_accessor :a, :b

    def product
      return nil if a.nil? || b.nil?
      a * b
    end

    def sum
      return nil if a.nil? || b.nil?
      a + b
    end
  end
end
