# 次の仕様を満たす、SimpleModelモジュールを作成してください
#
# 1. include されたクラスがattr_accessorを使用すると、以下の追加動作を行う
#   1. 作成したアクセサのreaderメソッドは、通常通りの動作を行う
#   2. 作成したアクセサのwriterメソッドは、通常に加え以下の動作を行う
#     1. 何らかの方法で、writerメソッドを利用した値の書き込み履歴を記憶する
#     2. いずれかのwriterメソッド経由で更新をした履歴がある場合、 `true` を返すメソッド `changed?` を作成する
#     3. 個別のwriterメソッド経由で更新した履歴を取得できるメソッド、 `ATTR_changed?` を作成する
#       1. 例として、`attr_accessor :name, :desc`　とした時、このオブジェクトに対して `obj.name = 'hoge` という操作を行ったとする
#       2. `obj.name_changed?` は `true` を返すが、 `obj.desc_changed?` は `false` を返す
#       3. 参考として、この時 `obj.changed?` は `true` を返す
# 2. initializeメソッドはハッシュを受け取り、attr_accessorで作成したアトリビュートと同名のキーがあれば、自動でインスタンス変数に記録する
#   1. ただし、この動作をwriterメソッドの履歴に残してはいけない
# 3. 履歴がある場合、すべての操作履歴を放棄し、値も初期状態に戻す `restore!` メソッドを作成する

module SimpleModel
  def self.included(mod)
    mod.define_singleton_method(:attr_accessor) do |*names|
      mod.class_eval { @attributes = (@attributes || []) | names }

      names.each do |name|
        define_method(name) { instance_variable_get("@#{name}") }

        define_method("#{name}=") do |value|
          histories = (instance_variable_get("@#{name}_histories") || []) << value
          instance_variable_set("@#{name}_histories", histories)
          instance_variable_set("@#{name}", value)
        end

        define_method("#{name}_changed?") do
          initial_val = instance_variable_get("@#{name}_initial_value")
          histories   = instance_variable_get("@#{name}_histories")

          return false unless initial_val && histories

          initial_val != histories.last
        end
      end
    end

    def initialize(attributes)
      attributes.each do |(key, val)|
        next unless defined_attributes.include?(key)
        instance_variable_set("@#{key}_initial_value", val)
        instance_variable_set("@#{key}", val)
      end
    end

    def changed?
      defined_attributes.any? do |attr|
        instance_variable_get("@#{attr}_histories")
      end
    end

    def restore!
      return unless changed?

      defined_attributes.each do |attr|
        next unless instance_variable_get("@#{attr}_histories")
        instance_variable_set("@#{attr}_histories", nil)
        instance_variable_set("@#{attr}", instance_variable_get("@#{attr}_initial_value"))
      end
    end

    private

    def defined_attributes
      @attributes ||= self.class.instance_variable_get(:@attributes)
    end
  end
end
