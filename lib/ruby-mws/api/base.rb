# This class serves as a parent class to the API classes.
# It shares connection handling, query string building, ?? among the models.

module MWS
  module API

    class Base
      include HTTParty
      parser MWS::API::BinaryParser
      debug_output $stderr  # only in development
      #format :xml
      headers "User-Agent"   => "ruby-mws/#{MWS::VERSION} (Language=Ruby/1.9.3-p0)"
      headers "Content-Type" => "text/xml"

      attr_accessor :response

      def initialize(connection)
        @connection = connection
        @saved_options = {}
        @next = {}
        self.class.base_uri "https://#{connection.host}"
      end

      def self.def_request(requests, *options)
        [requests].flatten.each do |name|
          self.class_eval %Q{
            @@#{name}_options = options.first
            def #{name}(params={})
              send_request(:#{name}, params, @@#{name}_options)
            end
          }
        end
      end

      def self.def_feed(requests, *options)
        [requests].flatten.each do |name|
          self.class_eval %Q{
            @@#{name}_options = options.first
            def #{name}(feed, params={})
              send_feed(:#{name}, feed, params, @@#{name}_options)
            end
          }
        end
      end

      def self.def_post(requests, *options)
        [requests].flatten.each do |name|
          self.class_eval %Q{
            @@#{name}_options = options.first
            def #{name}(params={})
              send_post(:#{name}, params, @@#{name}_options)
            end
          }
        end
      end

      def feed_valid? feed
        xsd_path = File.join(Rails.root,'lib','amazon','xsd','amzn-envelope.xsd')
        xsddoc = Nokogiri::XML(File.read(xsd_path), xsd_path)
        xsd = Nokogiri::XML::Schema.from_document(xsddoc)
        instance = Nokogiri::XML(feed)
        valid = true
        xsd.validate(instance).each do |error|
          valid = false
          puts "XML Validation Error: #{error}"
        end
        valid
      end

      def send_feed(name, feed, params, options={})
        # prepare all required params...

        body = feed.to_xml unless feed.class == String

        return unless feed_valid? body

        params = [default_params('submit_feed'), params, options, @connection.to_hash].inject :merge

        params[:lists] ||= {}
        params[:lists][:marketplace_id] = "MarketplaceId.Id"

        query = Query.new params

        resp = self.class.send(params[:verb], query.request_uri, :body => body, :headers => {"Content-MD5" => Base64.encode64(Digest::MD5.digest(body))})

        @response = Response.parse resp, 'submit_feed', params

        feed.set_request_id @response.feed_submission_info.feed_submission_id if feed.respond_to?(:request)

        @response
      end

      def send_request(name, params, options={})

        # prepare all required params...
        params = [default_params(name), params, options, @connection.to_hash].inject :merge

        params[:lists] ||= {}
        params[:lists][:marketplace_id] = "MarketplaceId.Id" unless options[:single_marketplace]

        query = Query.new params

        if params[:report_id].present?
          if File.file?(Rails.root.join('mws','reports','ids',params[:report_id]))
            resp = File.read(Rails.root.join('mws','reports','ids',params[:report_id]))
            report_source = 'file'

          else

            resp = self.class.send(params[:verb], query.request_uri)
            File.write(Rails.root.join('mws','reports','ids',params[:report_id]), resp.body.encode("UTF-8", :invalid => :replace, :undef => :replace)) unless resp.nil? || resp["ErrorResponse"].present?
            resp = resp.body if resp["AmazonEnvelope"].present?
            report_source = 'url'
          end
        else
          resp = self.class.send(params[:verb], query.request_uri)
        end



        @response = Response.parse resp, name, params

        request_info = @response['report_request_info'] unless @response.is_a?(Array)

        AmazonRequest.create(:request_type => request_info['report_type'], :request_id => request_info['report_request_id'], :script => 'MWS::Reports#send_request') unless request_info.nil?

        if @response.respond_to?(:next_token) and @next[:token] = @response.next_token  # modifying, not comparing
          @next[:action] = name.match(/_by_next_token/) ? name : "#{name}_by_next_token"
        end
        @response
      end

      def send_post(name, params, options={})

        # prepare all required params...
        params = [default_params(name), params, options, @connection.to_hash].inject :merge

        params[:lists] ||= {}
        #params[:lists][:marketplace_id] = "MarketplaceId.Id"

        query = Query.new params

        if params[:report_id].present?
          if File.file?(Rails.root.join('mws','reports','ids',params[:report_id]))
            resp = File.read(Rails.root.join('mws','reports','ids',params[:report_id]))
            report_source = 'file'

          else

            resp = self.class.send(params[:verb], query.request_uri)
            File.write(Rails.root.join('mws','reports','ids',params[:report_id]), resp.body.encode("UTF-8", :invalid => :replace, :undef => :replace)) unless resp.nil? || resp["ErrorResponse"].present?
            resp = resp.body if resp["AmazonEnvelope"].present?
            report_source = 'url'
          end
        else
          resp = self.class.send(params[:verb], 'https://mws.amazonservices.com/FulfillmentInboundShipment/2010-10-01', :body => query.request_body, :headers => {'Content-Type' => 'application/x-www-form-urlencoded'})
        end



        @response = Response.parse resp, name, params

        request_info = @response['report_request_info']

        AmazonRequest.create(:request_type => request_info['report_type'], :request_id => request_info['report_request_id'], :script => 'MWS::Reports#send_request') unless request_info.nil?

        if @response.respond_to?(:next_token) and @next[:token] = @response.next_token  # modifying, not comparing
          @next[:action] = name.match(/_by_next_token/) ? name : "#{name}_by_next_token"
        end
        @response
      end

      def default_params(name)
        {
          :action            => name.to_s.camelize,
          :signature_method  => 'HmacSHA256',
          :signature_version => '2',
          :timestamp         => Time.now.iso8601,
          :version           => '2009-01-01'
        }
      end

      def has_next?
        not @next[:token].nil?
      end
      alias :has_next :has_next?

      def next
        self.send(@next[:action], :next_token => @next[:token]) unless @next[:token].nil?
      end

      def inspect
        "#<#{self.class.to_s}:#{object_id}>"
      end

    end

  end
end