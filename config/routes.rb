# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI - protected by authentication
  authenticate :user, ->(user) { user.memberships.exists?(role: :owner) } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Health check for load balancers
  get "up" => "health#show", as: :rails_health_check

  # Webhook ingest endpoint (public, no auth required)
  post "/ingest/:token", to: "ingest#receive", as: :ingest

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
      sessions: "users/sessions",
      passwords: "users/passwords"
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

    # Webhook management
    resources :sources do
      collection do
        get :new_modal
        post :create_modal
      end
      member do
        get :edit_modal
        patch :update_modal
      end
    end
    resources :destinations do
      collection do
        get :new_modal
        post :create_modal
      end
      member do
        get :edit_modal
        patch :update_modal
      end
    end
    resources :connections

    # Event and delivery logging
    resources :events, only: [:index, :show] do
      member do
        post :replay
      end
    end

    resources :deliveries, only: [:index, :show] do
      member do
        post :retry
      end
    end

    # Notification subscriptions management
    resources :notification_subscriptions, only: [:destroy]
  end
end
