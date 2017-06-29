class WebhookController < ApplicationController
  # Lineからのcallbackか認証
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    
    params = JSON.parse(request.body.read)
    
    event = params["events"][0]
    replyToken = event["replyToken"]
  
    docomo_client = DocomoClient.new(api_key: ENV["DOCOMO_API_KEY"])
      response = nil
      last_dialogue = LastDialogue.find_by(mid: params["id"])
      
      if last_dialogue.nil?
        response =  docomo_client.dialogue(params['text'])
        last_dialogue = LastDialogue.new(mid:params["id"], mode:response.body['mode'], da:response.body['da'], context:response.body['context'])
      else
        response =  docomo_client.dialogue(params['text'], last_dialogue.mode, last_dialogue.context)
        last_dialogue.mode = response.body['mode']
        last_dialogue.da = response.body['da']
        last_dialogue.context = response.body['context']
      end
      last_dialogue.save!
      message = response.body['utt']
    
      output_text = message

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end


  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end