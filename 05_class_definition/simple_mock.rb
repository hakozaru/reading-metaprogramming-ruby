# 次の仕様を満たすモジュール SimpleMock を作成してください
#
# SimpleMockは、次の2つの方法でモックオブジェクトを作成できます
# 特に、2の方法では、他のオブジェクトにモック機能を付与します
# この時、もとのオブジェクトの能力が失われてはいけません
# また、これの方法で作成したオブジェクトを、以後モック化されたオブジェクトと呼びます
# 1.
# ```
# SimpleMock.new
# ```
#
# 2.
# ```
# obj = SomeClass.new
# SimpleMock.mock(obj)
# ```
#
# モック化したオブジェクトは、expectsメソッドに応答します
# expectsメソッドには2つの引数があり、それぞれ応答を期待するメソッド名と、そのメソッドを呼び出したときの戻り値です
# ```
# obj = SimpleMock.new
# obj.expects(:imitated_method, true)
# obj.imitated_method #=> true
# ```
# モック化したオブジェクトは、expectsの第一引数に渡した名前のメソッド呼び出しに反応するようになります
# そして、第2引数に渡したオブジェクトを返します
#
# モック化したオブジェクトは、watchメソッドとcalled_timesメソッドに応答します
# これらのメソッドは、それぞれ1つの引数を受け取ります
# watchメソッドに渡した名前のメソッドが呼び出されるたび、モック化したオブジェクトは内部でその回数を数えます
# そしてその回数は、called_timesメソッドに同じ名前の引数が渡された時、その時点での回数を参照することができます
# ```
# obj = SimpleMock.new
# obj.expects(:imitated_method, true)
# obj.watch(:imitated_method)
# obj.imitated_method #=> true
# obj.imitated_method #=> true
# obj.called_times(:imitated_method) #=> 2
# ```

module SimpleMock
  define_singleton_method(:new) do
    Class.new { include SimpleMock }.new
  end

  define_singleton_method(:mock) do |obj|
    obj.tap { |o| o.class.class_eval { include SimpleMock } }
  end

  def method_call_count_mapped
    @method_call_count_mapped ||= {}
  end

  def expects(method_name, return_value)
    define_singleton_method(method_name) do
      increment_call_count(method_name)
      return_value
    end
  end

  def watch(method_name)
    if self.class.instance_methods.include?(method_name)
      define_singleton_method method_name do |*args, &block|
        increment_call_count(method_name)
        super(*args, &block)
      end
    end

    method_call_count_mapped[method_name] ||= 0
  end

  def called_times(method_name)
    method_call_count_mapped[method_name]
  end

  private

  def increment_call_count(method_name)
    if method_call_count_mapped[method_name]
      method_call_count_mapped[method_name] += 1
    end
  end
end
