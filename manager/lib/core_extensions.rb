class Object
  def blank?
    respond_to?(:empty?) ? !!send(:empty?) : !self
  end

  def present?
    !blank?
  end
end

class NilClass
  def blank?
    true
  end
end

class FalseClass
  def blank?
    true
  end
end

class TrueClass
  def blank?
    false
  end
end

class Array
  alias blank? empty?
end

class Hash
  alias blank? empty?
end

class Numeric
  def blank?
    false
  end
end

class String
  def blank?
    empty? || /\A[[:space:]]*\z/.match?(self)
  end
end
