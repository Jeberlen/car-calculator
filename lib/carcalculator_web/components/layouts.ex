defmodule CarcalculatorWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use CarcalculatorWeb, :controller` and
  `use CarcalculatorWeb, :live_view`.
  """
  use CarcalculatorWeb, :html

  embed_templates "layouts/*"
end
