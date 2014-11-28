# Provide the shortcut `pry` to be used within any object
class Object
  def pry
    require 'pry'
    binding.pry
  end
end
