class Admin::Poll::QuestionsController < Admin::Poll::BaseController
  include CommentableActions
  include Translatable

  load_and_authorize_resource :poll
  load_and_authorize_resource :question, class: "Poll::Question"

  def index
    @polls = Poll.not_budget
    @questions = @questions.search(search_params).page(params[:page]).order("created_at DESC")

    @proposals = Proposal.successful.sort_by_confidence_score
  end

  def new
    @polls = Poll.all
    proposal = Proposal.find(params[:proposal_id]) if params[:proposal_id].present?
    @question.copy_attributes_from_proposal(proposal)
    @question.poll = @poll
  end

  def create
    @question.author = @question.proposal&.author || current_user

    if @question.save
      redirect_to admin_question_path(@question)
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to admin_question_path(@question), notice: t("flash.actions.save_changes.notice")
    else
      render :edit
    end
  end

  def destroy
    @question.destroy!
    redirect_to admin_poll_path(@question.poll), notice: t("admin.questions.destroy.notice")
  end

  private

    def question_params
      params.require(:poll_question).permit(allowed_params)
    end

    def allowed_params
      attributes = [:poll_id, :question, :proposal_id]

      [*attributes, translation_params(Poll::Question)]
    end

    def search_params
      params.permit(:poll_id, :search)
    end
end
