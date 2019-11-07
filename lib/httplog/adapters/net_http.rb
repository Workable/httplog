# frozen_string_literal: true

module Net
  class HTTP
    alias orig_request request unless method_defined?(:orig_request)
    alias orig_connect connect unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)
      url = "http://#{@address}:#{@port}#{req.path}"

      bm = Benchmark.realtime do
        @response = orig_request(req, body, &block)
      end

      if HttpLog.url_approved?(url) && started?
        HttpLog.call(
          method: req.method,
          url: url,
          request_body: req.body.nil? || req.body.empty? ? log_body(req, body) : req.body,
          request_headers: req.each_header.collect,
          response_code: @response.code,
          response_body: @response.body,
          response_headers: @response.each_header.collect,
          benchmark: bm,
          encoding: @response['Content-Encoding'],
          content_type: @response['Content-Type']
        )
      end

      @response
    end

    def connect
      HttpLog.log_connection(@address, @port) if !started? && HttpLog.url_approved?("#{@address}:#{@port}")

      orig_connect
    end

    private

    def log_body(req, body=nil)
      body.nil? || body.empty? ? log_body_stream(req.body_stream) : body
    end

    def log_body_stream(body_stream)
      if body_stream.nil?
        return nil
      else
        body_stream.instance_variable_get('@stream').seek(0)
        body_stream.to_s
      end
    end
  end
end
