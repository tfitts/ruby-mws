module MWS
  module API

    class Feed < Base

      def_feed [:inventory],
                  :verb => :post,
                  :uri => '/',
                  :version => '2009-01-01',
                  :feed_type => '_POST_INVENTORY_AVAILABILITY_DATA_'

      def_feed [:product],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_DATA_'

      def_feed [:relationship],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_RELATIONSHIP_DATA_'

      def_feed [:price],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_PRICING_DATA_'

      def_feed [:override],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_OVERRIDES_DATA_'

      def_feed [:image],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_IMAGE_DATA_'

      def_feed [:fulfillment],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PRODUCT_OVERRIDES_DATA_'

      def_feed [:acknowledgement],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'

      def_feed [:adjustment],
               :verb => :post,
               :uri => '/',
               :version => '2009-01-01',
               :feed_type => '_POST_PAYMENT_ADJUSTMENT_DATA_'

    end

  end
end