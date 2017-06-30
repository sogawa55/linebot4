require 'docomoru'
 
class DocomoClient
  def initialize(api_key = nil)
    @api_key = api_key
  end
 
  def dialogue(message, mode="dialogue", context=nil)
    client = Docomoru::Client.new(api_key: ENV["DOCOMO_API_KEY"])
    response = client.create_dialogue(message, {mode:mode, context:context})
 
    return response
  end
end