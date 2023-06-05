require "rails_helper"

describe User do
  describe ".maximum_attempts" do
    it "returns 20 as default when the secrets aren't configured" do
      expect(User.maximum_attempts).to eq 20
    end

    context "when secrets are configured" do
      before do
        allow(Rails.application).to receive(:secrets).and_return(ActiveSupport::OrderedOptions.new.merge(
          security: {
            lockable: { maximum_attempts: "14" }
          },
          tenants: {
            superstrict: {
              security: {
                lockable: { maximum_attempts: "1" }
              }
            }
          }
        ))
      end

      it "uses the general secrets for the main tenant" do
        expect(User.maximum_attempts).to eq 14
      end

      it "uses the tenant secrets for a tenant" do
        allow(Tenant).to receive(:current_schema).and_return("superstrict")

        expect(User.maximum_attempts).to eq 1
      end
    end
  end

  describe ".unlock_in" do
    it "returns 1 as default when the secrets aren't configured" do
      expect(User.unlock_in).to eq 1.hour
    end

    context "when secrets are configured" do
      before do
        allow(Rails.application).to receive(:secrets).and_return(ActiveSupport::OrderedOptions.new.merge(
          security: {
            lockable: { unlock_in: "2" }
          },
          tenants: {
            superstrict: {
              security: {
                lockable: { unlock_in: "5000" }
              }
            }
          }
        ))
      end

      it "uses the general secrets for the main tenant" do
        expect(User.unlock_in).to eq 2.hours
      end

      it "uses the tenant secrets for a tenant" do
        allow(Tenant).to receive(:current_schema).and_return("superstrict")

        expect(User.unlock_in).to eq 5000.hours
      end
    end
  end
end
