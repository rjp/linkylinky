module PluginSugar
  def def_field(*names)
    class_eval do 
      names.each do |name|
        define_method(name) do |*args| 
          case args.size
          when 0: instance_variable_get("@#{name}")
          else    instance_variable_set("@#{name}", *args)
          end
        end
      end
    end
  end
end

class PluginBase
  class << self
    extend PluginSugar
    def_field :author, :version
    def_field :match_host, :match_uri
    def_field :negative_match_uri
  end
end

