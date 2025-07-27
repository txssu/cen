# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule CenWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: CenWeb.Gettext

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-fit max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white px-12 pt-11 pb-7 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 hover:opacity-50"
                  aria-label={gettext("close")}
                >
                  <.icon name="cen-cross" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def filters_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="min-h-full w-full items-center justify-center">
          <div class="w-full">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-5 shadow-lg ring-1 transition"
            >
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 z-50 mr-2 w-80 rounded-lg p-3 ring-1 sm:w-96",
        @kind == :info && "bg-emerald-50 fill-cyan-900 text-emerald-800 ring-emerald-500",
        @kind == :error && "bg-rose-50 fill-rose-900 text-rose-900 shadow-md ring-rose-500"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div>
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-[1.875rem]">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={["shadow-default-1 flex items-center rounded-full font-normal uppercase", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :arrow_direction, :string, values: ~w(left right), default: "right"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def arrow_button(assigns) do
    ~H"""
    <.button class={["bg-accent pl-[0.4375rem] text-[0.9375rem] gap-2.5 py-2 pr-5", @class]} type={@type} {@rest}>
      <.icon class="h-[1.875rem] shadow-icon rounded-full bg-white" name={"cen-arrow-#{@arrow_direction}"} />
      <span class="text-white">
        {render_slot(@inner_block)}
      </span>
    </.button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def regular_button(assigns) do
    ~H"""
    <.button class={["text-[0.9375rem] px-5 py-4 ", @class]} type={@type} {@rest}>
      <span class="text-title-text">
        {render_slot(@inner_block)}
      </span>
    </.button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :implicit_required, :boolean, default: false
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week textcard)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :required, :boolean, default: false

  attr :text_before, :string, default: nil, doc: "text before the input in textcard"
  attr :text_after, :string, default: nil, doc: "text after the input in textcard"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly rows size step)

  slot :label_block

  def input(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign(:required, assigns.required or assigns.implicit_required)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", multiple: true} = assigns) do
    assigns =
      if is_nil(assigns.value),
        do: assigns,
        else: assign(assigns, :value, Enum.map(assigns.value, &to_string/1))

    ~H"""
    <div>
      <input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />
      <.label for={@id}>
        {@label}{if @required && @label && !@implicit_required, do: "*"}
      </.label>
      <div class="mt-4 ml-2 flex flex-col">
        <label :for={{option_label, option_value} <- @options} class="text-lg">
          <input
            type="checkbox"
            id={"#{@id}[#{option_value}]"}
            name={@name}
            value={option_value}
            checked={@value && option_value in @value}
            class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
            {@rest}
          />
          {option_label}
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          required={@required}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
        {render_slot(@label_block)}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <input :if={@multiple} type="hidden" name={@name} />
      <.label for={@id}>
        {@label}{if @required && @label && !@implicit_required, do: "*"}
      </.label>
      <select
        id={@id}
        name={@name}
        class={[
          "h-[3.625rem] shadow-input text-regulargray mt-[0.9375rem] block w-full rounded-lg border-0 font-light placeholder:text-text focus:ring-0 disabled:opacity-50",
          @multiple && "overflow-y-auto lg:h-auto"
        ]}
        multiple={@multiple}
        size={if @multiple, do: Enum.count(@options)}
        required={@required}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>
        {@label}{if @required && @label && !@implicit_required, do: "*"}
      </.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "min-h-[6rem] h-[3.625rem] shadow-input text-regulargray mt-[0.9375rem] block w-full rounded-lg border-0 font-light placeholder:text-text focus:ring-0",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        required={@required}
        {@rest}
      ><%= Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textcard"} = assigns) do
    ~H"""
    <div class="shadow-textcard rounded-lg bg-white px-8 py-4">
      <label for={@id} class="text-title-text leading-[1.3rem] block uppercase lg:text-xl">
        {@label}{if @required && @label && !@implicit_required, do: "*"}
      </label>
      <div class="mt-4 flex items-center gap-4">
        <div class="text-regulargray">{@text_before}</div>
        <input
          type="text"
          name={@name}
          id={@id}
          value={Form.normalize_value(@type, @value)}
          class={[
            "shadow-default-convexity text-regulargray h-11 w-24 rounded-lg border-0 font-light placeholder:text-text focus:ring-0",
            @errors == [] && "border-zinc-300 focus:border-zinc-400",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
          required={@required}
          {@rest}
        />
        <div class="text-regulargray">{@text_after}</div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>
        {@label}{if @required && @label && !@implicit_required, do: "*"}
      </.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Form.normalize_value(@type, @value)}
        class={[
          "h-[3.625rem] shadow-input text-regulargray mt-[0.9375rem] flex w-full items-center rounded-lg border-0 font-light placeholder:text-text focus:ring-0",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        required={@required}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="text-title-text mt-[1.5625rem] leading-[1.3rem] block uppercase lg:text-xl">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  attr :header_level, :string, default: "h1"

  attr :header_kind, :string, required: true, values: ~w[blue_center black_center blue_left black_left]

  slot :subtitle
  slot :inner_block, required: true

  def header(assigns) do
    ~H"""
    <header class={@class}>
      <.dynamic_tag tag_name={@header_level} class={["leading-[1.2] text-2xl font-medium uppercase lg:text-3xl", header_kind_class(@header_kind)]}>
        {render_slot(@inner_block)}
      </.dynamic_tag>
      {render_slot(@subtitle)}
    </header>
    """
  end

  defp header_kind_class(header_kind) do
    case header_kind do
      "blue_center" -> "text-accent text-center"
      "black_center" -> "text-title-text text-center"
      "blue_left" -> "text-accent"
      "black_left" -> "text-title-text"
    end
  end

  attr :class, :string, default: nil
  attr :legend, :string, required: true
  attr :subtitle, :string, default: nil

  slot :inner_block, required: true

  def fieldset(assigns) do
    ~H"""
    <fieldset class={@class}>
      <.header header_level="legend" header_kind="black_left">
        {@legend}
        <:subtitle>
          <%= if @subtitle do %>
            <p class="text-title-text leading-[1.3rem] mt-2.5 block uppercase lg:text-xl">
              {@subtitle}
            </p>
          <% end %>
        </:subtitle>
      </.header>
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  attr :text, :string, required: true

  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  def regular_link(assigns) do
    ~H"""
    <.link class="text-text font-normal underline hover:text-accent" {@rest}>
      {@text}
    </.link>
    """
  end

  attr :class, :string, default: nil
  attr :header, :string, default: nil

  slot :inner_block, required: true

  def basic_card(assigns) do
    ~H"""
    <div class={[@class, "bg-[#F5F5F5] shadow-default-convexity rounded-lg"]}>
      <h2 class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
        {@header}
      </h2>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :any, required: true
  slot :inner_block, required: true

  def render_not_nil(assigns)
  def render_not_nil(%{value: nil} = assigns), do: ~H""

  def render_not_nil(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-left text-sm leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span :for={action <- @action} class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :alt, :string, default: ""

  def icon(%{name: "hero-" <> _icon_name} = assigns) do
    ~H"""
    <span class={[@name, @class]} alt={@alt} />
    """
  end

  def icon(%{name: "cen-" <> _icon_name} = assigns) do
    ~H"""
    <img src={"/images/icons/#{@name}.svg"} alt={@alt} class={[@class]} />
    """
  end

  attr :display_pages_count, :integer, default: 5
  attr :metadata, Flop.Meta, required: true
  attr :path, :string, required: true

  def pagination(assigns) do
    min_page_num = max(1, min(assigns.metadata.current_page - 2, assigns.metadata.total_pages - 4))
    max_page_num = min(assigns.metadata.total_pages, max(assigns.metadata.current_page + 2, 5))

    assigns = assign(assigns, min_page_num: min_page_num, max_page_num: max_page_num)

    ~H"""
    <ul :if={@metadata.total_pages > 1} class="flex justify-center gap-4">
      <li class={@metadata.has_previous_page? || "invisible"}>
        <.button class="h-10 w-10 justify-center" type="button" phx-click="goto_page" phx-value-page={@metadata.previous_page}>
          <.icon name="cen-arrow-left" />
        </.button>
      </li>
      <li :for={page_num <- @min_page_num..@max_page_num}>
        <.button
          class={["h-10 w-10 justify-center", @metadata.current_page == page_num && "bg-accent text-white"]}
          disabled={@metadata.current_page == page_num}
          type="button"
          phx-click="goto_page"
          phx-value-page={page_num}
        >
          {page_num}
        </.button>
      </li>
      <li class={@metadata.has_next_page? || "invisible"}>
        <.button class="h-10 w-10 justify-center" type="button" phx-click="goto_page" phx-value-page={@metadata.next_page}>
          <.icon name="cen-arrow-right" />
        </.button>
      </li>
    </ul>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CenWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CenWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
