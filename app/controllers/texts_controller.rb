require 'httparty'

class TextsController < ApplicationController
  def new
  end

  def generate
    prompt = params[:prompt]
    formatted_prompt = prompt.gsub(/\s+/, ' ').strip
    puts formatted_prompt
    # Replace Hugging Face with GroqCloud API call
    response = HTTParty.post(
      "https://api.groq.com/openai/v1/chat/completions", # Update this to GroqCloud's endpoint
      headers: {
        "Authorization" => "Bearer #{ENV['GROQCLOUD_API_KEY']}", # Use GroqCloud API key
        "Content-Type" => "application/json"
      },
      body: {
        "messages": [{"role": "user", "content": "#{formatted_prompt}"}],
        "model": "llama3-8b-8192"
    }.to_json
    )
  
    # binding.pry
    if response.success?
      begin
        data = JSON.parse(response.body)["choices"]&.first["message"]["content"]
        fm = format_output(data)
        data ||= ""
        fm ||= []
        # Kết quả cuối cùng
        @output = "#{data} ======  #{fm.join('; ')}"
        binding.pry
      rescue JSON::ParserError
        @output = "Invalid JSON response from the server."
      end
    else
      @output = "Error generating text. Please try again."
    end
  
    flash[:output] = @output
    redirect_to :new_text
  end
  
  def new_text
  end

  private

  def format_output(output)
    cleaned_output = output.gsub(/[^a-zA-Z0-9,.\[\]()]/, '').strip
    match = cleaned_output.match(/\[([^\]]+)\]/)
  
    if match
      raw_content = match[1].strip
      begin
        return JSON.parse("[#{raw_content}]")
      rescue JSON::ParserError
        return raw_content.split(',').map(&:strip)
      end
    end
    []
  end
  
end  

