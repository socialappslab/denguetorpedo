# See: http://stackoverflow.com/questions/2713105/ruby-rails-jquery-uploadify-weird-utf-8-error
module ActiveSupport::JSON::Encoding
  def self.escape(string)
    if string.respond_to?(:force_encoding)
       string = string.encode(::Encoding::UTF_8, :undef => :replace).force_encoding(::Encoding::BINARY)
    end
    json = string.gsub(escape_regex) { |s| ESCAPED_CHARS[s] }
    json = %("#{json}")
    json.force_encoding(::Encoding::UTF_8) if json.respond_to?(:force_encoding)
    json
  end
end
