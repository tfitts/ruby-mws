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
            File.write(Rails.root.join('mws','reports',report_info.report_type,"#{report_info.report_id}.xml"), report)
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
        end

      end

    end

  end
end