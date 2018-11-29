
module SynapsePayRest

  class Subnet
  
    attr_accessor  :subnet_id, :payload

    def initialize(subnet_id:, payload:)
      @subnet_id = subnet_id 
      @payload = payload
    end
  end

  def get_subnet()
  end

  def get_all_subnet()
  end

  private 

end
