module CredSummoner
  class Account
    attr_reader :name, :id

    def initialize(name, id)
      @name = name
      @id = id
    end

    def to_s
      name
    end
  end
end
