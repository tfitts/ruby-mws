module MWS
  module API

    class Products < Base
      def_request [:get_matching_product_for_id],
                  :verb => :post,
                  :uri => '/Products',
                  :version => '2011-10-01',
                  :single_marketplace => true,
                  :lists => {
                      :asins => "IdList.Id",
                      :upc => "IdList.Id"
                  }

    end

  end
end