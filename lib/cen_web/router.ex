defmodule CenWeb.Router do
  use CenWeb, :router

  import CenWeb.UserAuth

  @nonce 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CenWeb.Layouts, :root}
    plug :protect_from_forgery

    plug CenWeb.Plugs.PutSecureHeaders

    plug :fetch_current_user
    plug CenWeb.Plugs.AlertUserChooseRole
  end

  pipeline :dev_dashboard do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug CenWeb.Plugs.CSPNonce, nonce: @nonce
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'self' 'nonce-#{@nonce}'"}
  end

  pipeline :mailbox do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'unsafe-inline'"}
  end

  ## Authentication routes

  scope "/", CenWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{CenWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    get "/users/auth/vkid", UserSessionController, :auth_vkid
  end

  scope "/", CenWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CenWeb.UserAuth, :ensure_authenticated}, CenWeb.ChatHook, CenWeb.NotificationsHook] do
      scope "/users/settings", UserSettings do
        live "/personal", PersonalInfoLive
        live "/personal/delete", PersonalInfoLive, :confirm_delete_user
        live "/credentials", CredentialsLive, :edit_credentials
        live "/confirm_email/:token", CredentialsLive, :confirm_email
      end

      scope "/users", UserLive do
        live "/", Index
        live "/choose_role", ChooseRole
      end

      scope "/orgs", OrganizationLive do
        live "/", Index
        live "/new", Form, :create
        live "/:id", Show
        live "/:id/edit", Form, :update
      end

      scope "/jobs", VacancyLive do
        live "/", Index, :index_for_user
        live "/review", Index, :index_for_review

        live "/search", Search

        live "/new", Form, :create
        live "/:id/edit", Form, :update

        live "/:id", Show, :show
        live "/:id/choose_resume", Show, :choose_resume
      end

      scope "/cvs", ResumeLive do
        live "/", Index, :index_for_user
        live "/review", Index, :index_for_review

        live "/search", Search

        live "/new", Form, :create
        live "/:id/edit", Form, :update

        live "/:id", Show, :show
        live "/:id/choose_vacancy", Show, :choose_vacancy
      end

      live "/res", InteractionLive, :responses
      live "/res/jobs/:id", VacancyLive.Show, :show
      live "/res/cvs/:id", ResumeLive.Show, :show

      live "/invs", InteractionLive, :invitations
      live "/invs/jobs/:id", VacancyLive.Show, :show
      live "/invs/cvs/:id", ResumeLive.Show, :show
    end
  end

  scope "/", CenWeb do
    pipe_through [:browser]

    delete "/users", UserController, :delete
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{CenWeb.UserAuth, :mount_current_user}, CenWeb.ChatHook, CenWeb.NotificationsHook] do
      live "/", HomeLive
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cen, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev/dashboard" do
      pipe_through :dev_dashboard
      live_dashboard "/", metrics: CenWeb.Telemetry, csp_nonce_assign_key: :csp_nonce
    end

    scope "/dev/mailbox" do
      pipe_through :mailbox
      forward "/", Plug.Swoosh.MailboxPreview
    end
  end
end
