# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI - protected by authentication
  authenticate :user, ->(user) { user.memberships.exists?(role: :owner) } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirect to default locale
  root to: redirect("/en")

  # Locale-scoped routes
  scope "/:locale", locale: /en/ do
    # Devise routes with custom paths
    devise_for :users, path: "", path_names: {
      sign_in: "login",
      sign_out: "logout",
      sign_up: "signup",
      password: "password",
      confirmation: "confirmation"
    }, controllers: {
      registrations: "users/registrations",
      sessions: "users/sessions"
    }

    # Authenticated root
    authenticated :user do
      root to: "dashboard#index", as: :authenticated_root
    end

    # Unauthenticated root
    unauthenticated do
      root to: redirect("/%{locale}/login"), as: :unauthenticated_root
    end

    # Dashboard
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Team management
    resources :team, only: [:index, :destroy] do
      collection do
        get "invite", action: :new_invite
        post "invite", action: :create_invite
      end
      member do
        patch "role", action: :update_role
      end
    end

    # Invitations (public access for accepting)
    resources :invitations, only: [:show], param: :token do
      member do
        post "accept"
      end
    end

    # Organization settings
    resource :settings, only: [:show, :update]
  end
end
