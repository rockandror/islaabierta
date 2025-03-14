require "rails_helper"

describe "Auditable" do
  before { allow(Rails.application.config).to receive(:auditing_enabled).and_return(true) }

  describe ".auditing_enabled" do
    context "when audited is disabled through secrets" do
      it "responds false to all classes" do
        allow(Rails.application.config).to receive(:auditing_enabled).and_return(false)

        ApplicationRecord.audited_class_names.each do |model|
          expect(model.constantize.auditing_enabled).to be(false)
        end
      end
    end

    context "when audited is enabled through secrets" do
      it "responds true to classes we want to keep track of changes" do
        ApplicationRecord.audited_class_names.sample do |model|
          expect(model.constantize.auditing_enabled).to be(true)
        end
      end

      it "responds false to classes we do not want to keep track of changes" do
        expect(ApplicationRecord.auditing_enabled).to be(false)
        expect(Administrator.auditing_enabled).to be(false)
        expect(Globalize::ActiveRecord::Translation.auditing_enabled).to be(false)
        expect(Visit.auditing_enabled).to be(false)
      end

      it "responds true to translation classes when globalized_model has enabled auditing" do
        expect(Proposal::Translation.auditing_enabled).to be(true)
        expect(Budget::Translation.auditing_enabled).to be(true)
        expect(Debate::Translation.auditing_enabled).to be(true)
      end

      it "responds false to translation classes when globalized_model has disabled auditing" do
        expect(Proposal::Translation.auditing_enabled).to be(true)

        allow(Proposal).to receive(:audited_class_names).and_return([])

        expect(Proposal::Translation.auditing_enabled).to be(false)
      end
    end
  end

  describe ".audited_columns" do
    context "on globalize translation classes" do
      it "returns the globalized model translatable attributes and the foreign key" do
        audited_columns = %w[proposal_id title description summary retired_explanation]

        expect(Proposal::Translation.audited_columns).to include(*audited_columns)

        ignored_attributes = %w[hidden_at locale]

        expect(Proposal::Translation.audited_columns).not_to include(*ignored_attributes)
        expect(Debate::Translation.audited_columns).not_to include(*ignored_attributes)
        expect(Banner::Translation.audited_columns).not_to include(*ignored_attributes)
        expect(Budget::Investment::Translation.audited_columns).not_to include(*ignored_attributes)
      end
    end

    context "on application record subclasses" do
      it "returns all the columns but the translations" do
        proposal_columns = %w[author_id hidden_at flags_count ignored_flag_at cached_votes_up comments_count
          tsv geozone_id retired_at retired_reason community_id published_at selected]

        expect(Proposal.audited_columns).to include(*proposal_columns)
        expect(Proposal.audited_columns).not_to include(*Proposal.translated_attribute_names)
      end
    end
  end

  describe "on auditable create" do
    it "keeps track of changes" do
      expect { create(:proposal) }.to change { Audit.count }
      expect { create(:debate) }.to change { Audit.count }
      expect { create(:poll) }.to change { Audit.count }
      expect { create(:widget_card) }.to change { Audit.count }
    end
  end

  describe ".audit_associated_with" do
    it "returns the globalized_model for any translation class" do
      expect(Budget::Investment::Translation.audit_associated_with).to eq(:globalized_model)
      expect(Debate::Translation.audit_associated_with).to eq(:globalized_model)
      expect(Legislation::Process::Translation.audit_associated_with).to eq(:globalized_model)
      expect(Poll::Translation.audit_associated_with).to eq(:globalized_model)
      expect(Proposal::Translation.audit_associated_with).to eq(:globalized_model)
    end

    it "returns the method for the current class name" do
      expect(Comment.audit_associated_with).to eq(:commentable)
      expect(Document.audit_associated_with).to eq(:documentable)
      expect(Dashboard::AdministratorTask.audit_associated_with).to eq(:source)
      expect(Flag.audit_associated_with).to eq(:flaggable)
      expect(Follow.audit_associated_with).to eq(:followable)
      expect(Image.audit_associated_with).to eq(:imageable)
      expect(Link.audit_associated_with).to eq(:linkable)
      expect(Milestone.audit_associated_with).to eq(:milestonable)
      expect(MlSummaryComment.audit_associated_with).to eq(:commentable)
      expect(Notification.audit_associated_with).to eq(:notifiable)
      expect(ProgressBar.audit_associated_with).to eq(:progressable)
      expect(RelatedContent.audit_associated_with).to eq(:parent_relationable)
      expect(Report.audit_associated_with).to eq(:process)
      expect(SDG::Relation.audit_associated_with).to eq(:relatable)
      expect(SDG::Review.audit_associated_with).to eq(:relatable)
      expect(SignatureSheet.audit_associated_with).to eq(:signable)
      expect(StatsVersion.audit_associated_with).to eq(:process)
      expect(Tagging.audit_associated_with).to eq(:taggable)
      expect(VotationType.audit_associated_with).to eq(:questionable)
      expect(Widget::Card.audit_associated_with).to eq(:cardable)
    end
  end

  describe "on auditable destroy" do
    context "when auditable has translations" do
      it "keeps track of model and translation" do
        proposal = create(:proposal)

        expect { proposal.destroy! }.to change { Audit.count }.by(2)
      end
    end

    context "when auditable does not have translations" do
      it "keeps track of model" do
        setting = create(:setting)

        expect { setting.destroy! }.to change { Audit.count }.by(1)
      end
    end
  end

  describe "on auditable update" do
    it "keeps track of resources and theirs translations from auditing enabled classes" do
      investment = create(:budget_investment)

      expect { investment.update!(title: "Updated title") }.to change { Audit.count }.by(1)
    end

    it "keeps track of resources translatable fields but ignores excluded columns" do
      translation = create(:budget_investment).translation

      expect { translation.update!(title: "Updated title") }.to change { Audit.count }.by(1)
      expect { translation.update!(hidden_at: Time.current, locale: "es") }.not_to change { Audit.count }
    end

    it "translation related audits are associated with the globalized model instance" do
      translation = create(:budget_investment).translation

      expect { translation.update!(title: "Updated title") }.to change { Audit.count }.by(1)
      expect(Audit.last.associated).to eq(translation.globalized_model)
    end

    it "does not keep track of explicitly excluded fields" do
      user = create(:user)

      expect(User.audited_columns).not_to be_empty
      expect(User.audited_columns).not_to include(*%w[sign_in_count last_sign_in_at current_sign_in_at])
      expect { user.update!(sign_in_count: 2) }.not_to change { Audit.count }
    end

    it "does not keep track of resources from auditing disabled classes" do
      allow(Budget::Investment).to receive(:auditing_enabled).and_return(false)
      investment = create(:budget_investment)

      expect { investment.update!(title: "Updated title") }.not_to change { Audit.count }

      visit = create(:visit)

      expect { visit.update!(user_agent: "firefox") }.not_to change { Audit.count }
    end
  end
end
