defmodule CenWeb.ErrorHTMLTest do
  use CenWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(CenWeb.ErrorHTML, "404", "html", %{status: 404}) =~ "404"
  end

  test "renders 500.html" do
    assert render_to_string(CenWeb.ErrorHTML, "500", "html", %{status: 500}) =~ "500"
  end
end
