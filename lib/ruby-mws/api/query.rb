module MWS
  module API

    class Query

      def initialize(params)
        @params = params
        params[:lists].each do |field,label|
          [params.delete(field)].compact.flatten.each_with_index do |item,i|
            params["#{label}.#{i+1}"] = item
          end
        end unless params[:lists].nil?

        params[:nested].each do |field,label|
          [params.delete(field)].each_with_index do |item,i|
            item.each do |f, v|
              params["#{label}.#{f}"] = v
            end
          end unless params[field].nil?
        end unless params[:nested].nil?

        params[:nested_lists].each do |field,label|
          [params.delete(field)].first.each_with_index do |item,i|
            item.each do |f, v|
              params["#{label}.#{i+1}.#{f}"] = v
            end
          end unless params[field].nil?
        end unless params[:nested_lists].nil?
      end

      def canonical
        #"#{@params[:uri]}/#{@params[:version]}"
        [@params[:verb].to_s.upcase, @params[:host], @params[:uri], build_sorted_query].join("\n")
      end

      def signature
        digest = OpenSSL::Digest::Digest.new('sha256')
        key = @params[:secret_access_key]
        Base64.encode64(OpenSSL::HMAC.digest(digest, key, canonical)).chomp
      end

      def post_uri
        "https://" << @params[:host] << @params[:uri] << '/' << @params[:version]
      end

      def request_uri
        "https://" << @params[:host] << @params[:uri] << '?' << build_sorted_query(signature)
      end

      def request_body
        params = @params.dup.delete_if {|k,v| exclude_from_query.include? k}

        params[:signature] = signature
        params.stringify_keys!

        # hack to capitalize AWS in param names
        # TODO: Allow for multiple marketplace ids
        params = Hash[params.map{|k,v| [k.camelize.sub(/Aws/,'AWS'), v]}.sort]

      end

      private
      def build_sorted_query(signature=nil)
        params = @params.dup.delete_if {|k,v| exclude_from_query.include? k}
        params[:signature] = signature if signature
        params.stringify_keys!

        # hack to capitalize AWS in param names
        # TODO: Allow for multiple marketplace ids
        params = Hash[params.map{|k,v| [k.camelize.sub(/Aws/,'AWS'), v]}]

        params = params.sort.map! { |p| "#{p[0]}=#{process_param(p[1])}" }
        params.join('&')
      end

      def process_param(param)
        case param
        when Time, DateTime
          escape(param.iso8601)
        else
          escape(param.to_s)
        end
      end

      def escape(value)
        value.gsub(/([^a-zA-Z0-9_.~-]+)/) do
          '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
        end
      end

      def exclude_from_query
        [
          :verb,
          :host,
          :uri,
          :secret_access_key,
          :return,
          :lists,
          :nested,
          :nested_lists,
          :mods
        ]
      end

    end

  end
end