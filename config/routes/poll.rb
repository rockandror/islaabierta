resources :polls, only: [:show, :index] do
  member do
    get :stats
    get :results
  end

  resources :questions, controller: "polls/questions", shallow: true do
    post :answer, on: :member
    resources :answers, controller: "polls/answers", only: :destroy, shallow: false
  end
end
