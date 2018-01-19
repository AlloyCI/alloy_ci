defmodule AlloyCi.Web.InputHelpers do
  @moduledoc """
  """
  alias Phoenix.HTML.Form
  alias AlloyCi.Web.ViewHelpers
  use Phoenix.HTML

  def array_input(form, field) do
    values = Form.input_value(form, field) || []

    content_tag :div, id: "tags-container", class: "form-group", data: [index: Enum.count(values)] do
      values
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        tag_element(form, field, value, index)
      end)
    end
  end

  def tag_element(form, field, value, index) do
    id = Form.input_id(form, field)
    new_id = id <> "_#{index}"

    input_opts = [
      name: new_field_name(form, field),
      value: value,
      id: new_id <> "_input",
      class: "form-control"
    ]

    content_tag :div, class: "inline m-r-1", id: new_id do
      [
        Form.hidden_input(form, field, input_opts),
        content_tag :button,
          type: "button",
          class: "btn btn-sm btn-info remove-tag",
          data: [id: new_id] do
          [value <> " ", ViewHelpers.icon("close")]
        end
      ]
    end
  end

  defp new_field_name(form, field) do
    Form.input_name(form, field) <> "[]"
  end
end
