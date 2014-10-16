module MWS
  module API

    class Fulfillment < Base
      def_request [:request_report],
                  :verb => :post,
                  :uri => '/FulfillmentInboundShipment',
                  :version => '2010-10-01'

      def_request [:confirm_transport_request, :estimate_transport_request, :get_bill_of_lading, :get_package_labels, :get_transport_content, :list_inbound_shipment_items],
                  :verb => :post,
                  :uri => '/FulfillmentInboundShipment',
                  :version => '2010-10-01',
                  :lists => {
                      :report_id => "ReportIdList.Id"
                  }

      def_request [:list_inventory_supply, :list_inventory_supply_by_next_token],
                  :verb => :post,
                  :uri => '/FulfillmentInventory/2010-10-01',
                  :version => '2010-10-01',
                  :lists => {
                      :skus => 'SellerSkus.member'
                  }

      def_request [:get_service_status],
                  :verb => :post,
                  :uri => '/FulfillmentInboundShipment',
                  :version => '2010-10-01'

      def_post [:create_inbound_shipment, :create_inbound_shipment_plan, :list_inbound_shipment_items_by_next_token, :list_inbound_shipments, :list_inbound_shipments_by_next_token, :put_transport_content, :void_transport_request, :update_inbound_shipment],
                  :verb => :post,
                  :uri => '/FulfillmentInboundShipment/2010-10-01',
                  :version => '2010-10-01',
                  :lists => {
                      :status => "ShipmentStatusList.member",
                      :id => "ShipmentIDList.member"
                  },
                  :nested => {
                      :ship_from_address => 'ShipFromAddress',
                      :header => 'InboundShipmentHeader',
                      :header_address => 'InboundShipmentHeader.ShipFromAddress'
                  },
                  :nested_lists => {
                      :plan_item => "InboundShipmentPlanRequestItems.member",
                      :shipment_items => "InboundShipmentItems.member",
                      :npsp => 'TransportDetails.NonPartneredSmallParcelData.PackageList.member'
                  }

    end

  end
end