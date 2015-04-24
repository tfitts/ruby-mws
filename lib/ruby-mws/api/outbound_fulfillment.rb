module MWS
  module API

    class OutboundFulfillment < Base

      def_request [:get_service_status],
                  :verb => :post,
                  :uri => '/FulfillmentOutboundShipment',
                  :version => '2010-10-01'

      def_post [:cancel_fulfillment_order, :create_fulfillment_order, :update_fulfillment_order, :get_fulfillment_order, :get_fulfillment_preview, :get_package_tracking_details, :list_all_fulfillment_orders, :list_all_fulfillment_orders_by_next_token ],
                  :verb => :post,
                  :uri => '/FulfillmentInboundShipment/2010-10-01',
                  :version => '2010-10-01',
                  :lists => {
                      :status => "ShipmentStatusList.member",
                      :id => "ShipmentIDList.member"
                  },
                  :address => {
                      :destination_address => 'DestinationAddress',
                      :header => 'InboundShipmentHeader',
                      :header_address => 'InboundShipmentHeader.ShipFromAddress'
                  },
                  :nested_lists => {
                      :items => "Items.member",
                      :shipment_items => "InboundShipmentItems.member",
                      :npsp => 'TransportDetails.NonPartneredSmallParcelData.PackageList.member'
                  }

    end

  end
end