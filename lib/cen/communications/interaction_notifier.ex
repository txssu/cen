defmodule Cen.Communications.InteractionNotifier do
  @moduledoc false
  import Swoosh.Email

  alias Cen.Communications.Interaction
  alias Cen.Mailer
  alias Cen.Repo

  @spec deliver_interaction_email(
          Interaction.t(),
          String.t(),
          (atom(), integer() -> String.t())
        ) :: {:ok, Swoosh.Email.t()} | {:error, term()}
  def deliver_interaction_email(%Interaction{} = interaction, message_text, url_fun) when is_function(url_fun, 2) do
    interaction
    |> preload_related()
    |> prepare_email_content(message_text, url_fun)
    |> build_email()
    |> Mailer.deliver()
  end

  defp preload_related(interaction), do: Repo.preload(interaction, vacancy: [:user], resume: [:user])

  defp prepare_email_content(%Interaction{initiator: initiator} = interaction, message_text, url_fun) do
    case initiator do
      :resume -> prepare_resume_email(interaction, message_text, url_fun)
      :vacancy -> prepare_vacancy_email(interaction, message_text, url_fun)
    end
  end

  defp prepare_resume_email(%Interaction{vacancy: vacancy, resume: resume}, message_text, url_fun) do
    recipient = vacancy.user.email
    subject = "Новый отклик на вашу вакансию"
    link = url_fun.(:vacancy, vacancy.id)

    body =
      """
      Здравствуйте #{vacancy.user.fullname},

      Пользователь #{resume.user.fullname} откликнулся на вашу вакансию "#{vacancy.job_title}".
      #{message_section(message_text)}
      Перейти к вакансии: #{link}
      """

    {recipient, subject, body}
  end

  defp prepare_vacancy_email(%Interaction{vacancy: vacancy, resume: resume}, message_text, url_fun) do
    recipient = resume.user.email
    subject = "Приглашение на вакансию"
    link = url_fun.(:resume, resume.id)

    body =
      """
      Здравствуйте #{resume.user.fullname},

      Пользователь #{vacancy.user.fullname} пригласил вас на вакансию "#{vacancy.job_title}".
      #{message_section(message_text)}
      Перейти к резюме: #{link}
      """

    {recipient, subject, body}
  end

  defp message_section(""), do: ""
  defp message_section(text), do: "Сообщение:\n#{text}\n\n"

  defp build_email({recipient, subject, body}) do
    new()
    |> to(recipient)
    |> from({"ТОН: Вакансии", email_from()})
    |> subject(subject)
    |> text_body(body)
  end

  defp email_from, do: Application.get_env(:cen, :email_from)
end
