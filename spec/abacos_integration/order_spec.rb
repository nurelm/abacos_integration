require 'spec_helper'

module AbacosIntegration
  describe Order do
    include_examples "config"
    let(:order_payload) { Factory.order }

    it "creates order in abacos" do
      # NOTE cpf can only have numbers
      #
      # NOTE Need to parse and format the date according to Abacos
      order_payload[:placed_on] = "02102014 00:12:00.000"

      subject = described_class.new(config, order: order_payload)

      VCR.use_cassette "orders/#{order_payload[:id]}" do
        subject.create
      end
    end
  end
end
