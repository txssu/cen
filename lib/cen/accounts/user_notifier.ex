defmodule Cen.Accounts.UserNotifier do
  @moduledoc false
  import Swoosh.Email

  alias Cen.Accounts.User
  alias Cen.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, text) do
    email =
      new()
      |> to(recipient)
      |> from({"ТОН: Вакансии", email_from()})
      |> subject(subject)
      |> text_body(text)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  @spec deliver_confirmation_instructions(User.t(), String.t()) :: {:ok, Swoosh.Email.t()} | {:error, term()}
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Инструкции по подтверждению", """

    Здравствуйте, #{user.email},

    Вы можете подтвердить свою учетную запись, посетив следующий URL:

    #{url}

    Если вы не создавали учетную запись у нас, просто проигнорируйте это сообщение.
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  @spec deliver_reset_password_instructions(User.t(), String.t()) :: {:ok, Swoosh.Email.t()} | {:error, term()}
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Инструкции по сбросу пароля", """

    Здравствуйте, #{user.email},

    Вы можете сбросить свой пароль, посетив следующий URL:

    #{url}

    Если вы не запрашивали сброс пароля, просто проигнорируйте это сообщение.
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(User.t(), String.t()) :: {:ok, Swoosh.Email.t()} | {:error, term()}
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Инструкции по обновлению email", """

    Здравствуйте, #{user.email},

    Вы можете изменить свой email, посетив следующий URL:

    #{url}

    Если вы не запрашивали обновление email, просто проигнорируйте это сообщение.
    """)
  end

  defp email_from do
    Application.get_env(:cen, :email_from)
  end
end
