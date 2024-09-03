require "rails_helper"

describe Layout::FooterComponent do
  describe "collaboration section" do
    it "displays the collaboration image with correct alt text and link" do
      I18n.with_locale(:es) { render_inline Layout::FooterComponent.new }

      page.find ".footer-sections .collaboration" do
        expect(page).to have_css ".collaboration-text", text: "Colabora"

        expect(page).to have_link href: "https://cabildoabierto.tenerife.es/"
        expect(page).to have_css "img[alt='Cabildo de Tenerife']"
      end
    end
  end
end
