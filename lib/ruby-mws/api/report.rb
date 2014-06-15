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

    end

  end
end