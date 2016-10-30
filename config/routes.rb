# Rails.application.routes.draw do
#   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
#   get 'welcome/new'
#   post 'welcome/new'
#   root 'welcome#index'
# end

WashOutSample::Application.routes.draw do
  # root :to => 'welcome#index'
  wash_out :rumbas
end
