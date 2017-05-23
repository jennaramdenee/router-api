module JSONRequestHelper
  def put_json(path, attrs, headers = {})
    put path, params: attrs.to_json, headers: {"CONTENT_TYPE" => "application/json"}.merge(headers)
  end
end

RSpec.configuration.include JSONRequestHelper, type: :request
