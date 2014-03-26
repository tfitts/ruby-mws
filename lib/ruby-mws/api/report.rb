module MWS
  module API

    class Report < Base
      def_request [:request_report],
                  :verb => :post,
                  :uri => '/',
                  :version => '2009-01-01'

      def_request [:update_report_acknowledgements],
                  :verb => :post,
                  :uri => '/',
                  :version => '2009-01-01',
                  :lists => {
                      :report_id => "ReportIdList.Id"
                  }

      def_request [:get_report],
                  :verb => :get,
                  :uri => '/',
                  :version => '2009-01-01'

      def_request [:get_report_request_list, :get_report_request_list_by_next_token, :get_report_list, :get_report_list_by_next_token],
                  :verb => :get,
                  :uri => '/',
                  :version => '2009-01-01',
                  :lists => {
                      :report_type => "ReportTypeList.Type"
                  }


      def process report_info

        if report_info.report_type == 'FeedSummaryReport' && report_info.acknowledged == 'false'

          report = get_report :report_id => report_info.report_id
          unless report.nil?
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.xml"), report.encode("utf-8", :invalid => :replace, :undef => :replace))
            request = AmazonRequest.find_by_request_id report_info.report_request_id
            return update_report_acknowledgements :report_id => report_info.report_id if request.nil?
            request.report_received report_info.report_id


            result_info = Amazon::Envelope.parse report.to_s
            summary = result_info.messages.first.processing_report.summary
            results = result_info.messages.first.processing_report.results
            request.complete_success if summary.processed == summary.successful && summary.error == 0 && summary.warning == 0

            request.process_results results

            update_report_acknowledgements :report_id => report_info.report_id

          end
        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_V2_SETTLEMENT_REPORT_DATA_XML_"
          report = get_report :report_id => report_info.report_id
          unless report.nil?
            HTTParty.post("http://192.168.1.100/amazon/post.php",:body => {:report => Base64.encode64(report.to_s), :id => report_info.report_id})
            update_report_acknowledgements :report_id => report_info.report_id
          end
        elsif report_info.acknowledged == "false" && ["_GET_MERCHANT_LISTINGS_DATA_LITER_",
                                                      "_GET_REFERRAL_FEE_PREVIEW_REPORT_",
                                                      "_GET_V2_SETTLEMENT_REPORT_DATA_FLAT_FILE_",
                                                      "_GET_V2_SETTLEMENT_REPORT_DATA_FLAT_FILE_V2_",
                                                      "_GET_ALT_FLAT_FILE_PAYMENT_SETTLEMENT_DATA_",
                                                      "_GET_FLAT_FILE_PAYMENT_SETTLEMENT_DATA_",
                                                      "_GET_PAYMENT_SETTLEMENT_DATA_"].include?(report_info.report_type)
          #TODO decide if we want to do anything with these reports
          report = get_report :report_id => report_info.report_id
          unless report.nil?
            ext = report_info.report_type.include?("FLAT") ? ".tab" : ".xml"
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.#{ext}"), report.force_encoding("UTF-8"))
            update_report_acknowledgements :report_id => report_info.report_id
          end

        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_AFN_INVENTORY_DATA_"
          report = get_report :report_id => report_info.report_id
          unless report.nil?
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.xml"), report.force_encoding("UTF-8"))
            listings = CSV.parse(report, {:col_sep => "\t", :headers => true})
            listings.each do |listing|
              Item.where{(sku == listing["seller-sku"]) & (quantity != my{listing["Quantity Available"]})}.update_all(:supplier_quantity => listing["Quantity Available"])
            end
            update_report_acknowledgements :report_id => report_info.report_id
          end
        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_FLAT_FILE_ALL_ORDERS_DATA_BY_LAST_UPDATE_"
          update_report_acknowledgements :report_id => report_info.report_id
        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"

          report = get_report :report_id => report_info.report_id
          unless report.nil?
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.tab"), report.force_encoding("UTF-8"))
            order = ::Order.new.from_fba report
            update_report_acknowledgements :report_id => report_info.report_id
          end

        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_FLAT_FILE_ACTIONABLE_ORDER_DATA_"
          return update_report_acknowledgements :report_id => report_info.report_id

          report = get_report :report_id => report_info.report_id
          unless report.nil?
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.tab"), report.force_encoding("UTF-8"))
            lines = CSV.parse(report.gsub('"',"'"), {:col_sep => "\t", :headers => true})
            ids = []
            lines.each do |line|
              ids << line["order-id"]
            end
            Order.where{market_id.in(ids.uniq)}.joins(:shipment).where("[shipments].[order_status] = ?",'Shipped')
            #TODO send shipment data for missing shipments.
            #update_report_acknowledgements :report_id => report_info.report_id
          end

        elsif report_info.acknowledged == "false" && report_info.report_type == "_GET_FLAT_FILE_OPEN_LISTINGS_DATA_"
          report = get_report :report_id => report_info.report_id
          unless report.nil?
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.tab"), report.force_encoding("UTF-8"))
            request = AmazonRequest.find_by_request_id(report_info.report_request_id) || AmazonRequest.create(:request_id => report_info.report_request_id, :report_id => report_info.report_id, :request_type => report_info.report_type, :script => "MWS::Reports#process")
            lines = CSV.parse(report, {:col_sep => "\t", :headers => true})
            lines.each_slice(200) do |batch|
              inserts = []
              batch.each  do |line|
                inserts << "select #{request.id},'#{line["sku"]}','#{line["asin"]}',#{line["price"]},#{line["quantity"].to_i}"
              end
              ActiveRecord::Base.connection.execute("INSERT INTO amazon_open_listings (amazon_request_id, sku, asin, price, quantity) #{inserts.join(" UNION ALL ")} GO")
            end

            update_report_acknowledgements :report_id => report_info.report_id
          end

        end

      end

      def acknowledge report_id
        update_report_acknowledgements :report_id => report_id
      end

    end

  end
end