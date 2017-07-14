defmodule AlloyCi.Web.Router do
  use AlloyCi.Web, :router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # This plug will look for a Guardian token in the session in the default location
  # Then it will attempt to load the resource found in the JWT.
  # If it doesn't find a JWT in the default location it doesn't do anything
  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  # This pipeline is created for use within the admin namespace.
  # It looks for a valid token in the session - but in the 'admin' location of guardian
  # This keeps the session credentials seperate for the main site, and the admin site
  # It's very possible that a user is logged into the main site but not the admin
  # or it could be that you're logged into both.
  # This does not conflict with the browser_auth pipeline.
  # If it doesn't find a JWT in the location it doesn't do anything
  pipeline :admin_browser_auth do
    plug Guardian.Plug.VerifySession, key: :admin
    plug Guardian.Plug.LoadResource, key: :admin
  end

  # We need this pipeline to load the token when we're impersonating.
  # We don't want to load the resource though, just verify the token
  pipeline :impersonation_browser_auth do
    plug Guardian.Plug.VerifySession, key: :admin
  end

  pipeline :api do
    plug :accepts, ["json", "text"]
  end

  pipeline :github do
    plug AlloyCi.Plugs.GithubHeader
  end

  # This pipeline if intended for API requests and looks for the JWT in the "Authentication" header
  # In this case, it should be prefixed with "Bearer" so that it's looking for
  # Authentication: Bearer <jwt>
  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  scope "/", AlloyCi.Web do
    # We pipe this through the browser_auth to fetch logged in people
    # We pipe this through the impersonation_browser_auth to know if we're impersonating
    # We don't just pipe it through admin_browser_auth because that also loads the resource
    pipe_through [:browser, :browser_auth, :impersonation_browser_auth]

    get "/", PublicController, :index
    get "/register", PublicController, :register, as: :register
    delete "/logout", AuthController, :logout

    resources "/authentications", AuthenticationController, only: [:index]
    resources "/tokens", TokenController, only: [:index, :delete]

    resources "/projects", ProjectController do
      resources "/pipelines", PipelineController, only: [:create, :delete, :show]
      resources "/builds", BuildController, only: [:show]
    end
  end

  # This scope is the main authentication area for Ueberauth
  scope "/auth", AlloyCi.Web do
    pipe_through [:browser, :browser_auth] # Use the default browser stack

    get "/:provider", AuthController, :login
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
  end

  # This scope is intended for admin users.
  # Normal users can only go to the login page
  scope "/admin", AlloyCi.Web.Admin, as: :admin do
    pipe_through [:browser, :admin_browser_auth] # Use the default browser stack

    get "/login", SessionController, :new, as: :login
    get "/login/:provider", SessionController, :new
    post "/auth/:provider/callback", SessionController, :callback
    get "/logout", SessionController, :logout
    delete "/logout", SessionController, :logout, as: :logout
    post "/impersonate/:user_id", SessionController, :impersonate, as: :impersonation
    delete "/impersonate", SessionController, :stop_impersonating

    resources "/users", UserController, only: [:index, :show, :delete]
    resources "/projects", ProjectController, only: [:index, :show, :delete]
    resources "/runners", RunnerController, only: [:index, :show, :delete]
  end

  scope "/api/github", AlloyCi.Web.Api, as: :api do
    pipe_through [:api, :github]

    post "/handle_event", GithubEventController, :handle_event
  end

  scope "/api/v4", AlloyCi.Web.Api, as: :runner_api do
    pipe_through [:api]

    scope "/runners" do
      post "/", RunnerEventController, :register, as: :register
      delete "/", RunnerEventController, :delete, as: :delete
      post "/verify", RunnerEventController, :verify, as: :verify
    end

    scope "/jobs" do
      post "/request", BuildsEventController, :request, as: :verify
      put "/:id", BuildsEventController, :update
      patch "/:id/trace", BuildsEventController, :trace
      # add routes for artifacts here
    end
  end
end
