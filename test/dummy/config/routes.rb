Rails.application.routes.draw do
  mount FeedbackBoard::Engine => "/feedback"
end
