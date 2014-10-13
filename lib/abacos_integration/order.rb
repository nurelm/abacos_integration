module AbacosIntegration
  class Order < Base
    attr_reader :order_payload, :shipping_address_payload

    def initialize(config, payload = {})
      super config
      @order_payload = payload[:order] || {}
      @shipping_address_payload = order_payload[:shipping_address] || {}
    end

    def create
      send_customer_info
      Abacos.add_orders [build_order.translated]
    end

    def build_order
      order = Abacos::Order.new order_payload
      order.shipping = order_payload[:totals][:shipping]
      order.total = order_payload[:totals][:order]

      placed_on = Abacos::Helper.parse_timestamp order_payload[:placed_on]
      order.placed_on = placed_on
      order.paid = order_payload[:paid] || true

      if order.paid
        order.paid_at = if order_payload[:paid_at]
                          Abacos::Helper.parse_timestamp order_payload[:paid_at]
                        else
                          placed_on
                        end
      end


      if order_payload[:totals][:discount]
        order.dicount = order_payload[:totals][:discount]
      end

      order.shipping_name = "#{shipping_address_payload[:firstname]} #{shipping_address_payload[:lastname]}"
      order.shipping_address1 = shipping_address_payload[:address1]
      order.shipping_address2 = shipping_address_payload[:address2]
      order.shipping_city = shipping_address_payload[:city]
      order.shipping_state = shipping_address_payload[:state]
      order.shipping_zipcode = shipping_address_payload[:zipcode]

      order
    end

    def send_customer_info
      customer = Abacos::Customer.new customer_payload
      Abacos.add_customers [customer.translated]
    end

    def customer_payload
      {
        'firstname' => order_payload[:billing_address][:firstname],
        'lastname' => order_payload[:billing_address][:lastname],
        'email' => order_payload[:email],
        'cpf_or_cnpj' => order_payload[:cpf_or_cnpj],
        # NOTE Move defaults here to Abacos::Customer
        'kind' => order_payload[:kind] || "tpeFisica",
        'gender' => order_payload[:gender],
        'billing_address' => order_payload[:billing_address]
      }
    end

    # NOTE Map Order statuses (codigo_status). e.g.
    #
    #   ENT => delivered ?
    #
    def fetch
      Abacos.orders_available_status.map do |order|
        {
          id: order[:numero_pedido],
          abacos: order
        }
      end
    end
  end
end
