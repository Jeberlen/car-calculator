defmodule CarcalculatorWeb.MainPage do
  use CarcalculatorWeb, :live_view


  def render(assigns) do
    ~H"""
    <div class="container mx-auto">
      <img class="mb-10" src={~p"/images/svart-logotyp-liggande.png"} />
      <h1 class="text-3xl font-bold text-center">Förmånsbil uträkning</h1>
      <h2 class="text-center mb-10">Denna applikation ger en ungefärlig uträkning på faktisk kostnad brutto.</h2>
      <form phx-submit="submit">
        <div class="grid grid-cols-2 gap-4 mb-4 md:grid-cols-4 ">
          <label class="m-auto" for="income">Årsinkomst</label>
          <input id="income" name="income" type="number"  placeholder="749000" phx-debounce="500" phx-target="income" phx-value-model="income" class="border border-gray-300 rounded-md p-2" />

          <label class="m-auto" for="car-price-text-input">Nybilspris</label>
          <input id="car-price-text-input" name="price" type="number" placeholder="659000" phx-debounce="500" phx-target="price" phx-value-model="price" class="border border-gray-300 rounded-md p-2"/>

          <label class="m-auto" for="car-price-text-input">Leasingavgift</label>
          <input id="leasing-price-text-input" name="leasing-price" type="number" placeholder="3500" phx-debounce="500" phx-target="leasing_price" phx-value-model="leaseing_price" class="border border-gray-300 rounded-md p-2"/>

          <label class="m-auto" for="extras-text-input">Tillägg</label>
          <input id="extras-text-input" name="extras" type="number" phx-debounce="500" placeholder="30000" phx-target="extras" phx-value-model="extras" class="border border-gray-300 rounded-md p-2"/>

          <label class="m-auto" for="model-year">Modell år</label>
          <input id="model-year" name="model-year" type="number" phx-debounce="500" value="2025" phx-target="model_year" phx-value-model="model_year" class="border border-gray-300 rounded-md p-2" />

          <label class="m-auto" for="fuel-type">Bränsletyp</label>
          <select id="fuel-type" name="fuel-type" phx-target="fuel-type" phx-value-model="fuel_type" class="border border-gray-300 rounded-md p-2">
            <option value="petrol">Bensin</option>
            <option value="plugin-hybrid">Ladd-hybrid</option>
            <option value="electric">El</option>
          </select>

          <label class="m-auto" for="tax">Fordonskatt</label>
          <input id="tax" name="car-tax" type="number" phx-target="car_tax" placeholder="360" phx-value-model="car_tax" class="border border-gray-300 rounded-md p-2" />
        </div>
        <div class="flex justify-center mt-10">
          <button type="submit" class="w-48 bg-gray-900 text-white p-2 rounded-md">Räkna</button>
        </div>
      </form>
      <div class="mt-10">
        <%= for err <- @error do %>
            <div class="text-red-500 text-center"><%= err %></div>
        <% end %>
      </div>
      <div class="flex flex-col items-center mt-10">
        <div class="mb-10">
          <h1 class="text-2xl font-bold text-center mb-5">Kalkuleringsdelar</h1>
          <h2 class="text-xl text-center">Total kostnad / månad: <%= @monthly_cost_and_tax %></h2>
          <h2 class="text-xl text-center">Total kostnad / år: <%= @yearly_cost_and_tax %></h2>
          <h2 class="text-xl text-center">Månadskostnad: <%= @monthly_cost %></h2>
          <h2 class="text-xl text-center">Årskostnad: <%= @yearly_cost %></h2>
          <h2 class="text-xl text-center">Extra skatt / månad: <%= @monthly_tax %></h2>
          <h2 class="text-xl text-center">Extra skatt / år: <%= @yearly_cost %></h2>
        </div>
      </div>
    </div>
    """
  end
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      income: 0,
      price: 0,
      leasing_price: 0,
      extras: 0,
      model_year: 2025,
      fuel_type: "",
      car_tax: 0,
      monthly_cost: "-",
      yearly_cost: "-",
      monthly_cost_and_tax: "-",
      yearly_cost_and_tax: "-",
      monthly_tax: "-",
      yearly_tax: "-",
      error: [])
    }
  end

  def handle_event("submit", %{"income" => income, "price" => price, "leasing-price" => leasing_price, "extras" => extras,
    "model-year" => model_year, "fuel-type" => fuel_type, "car-tax" => car_tax}, socket) do
    # Handle the form submission, e.g., save to the database or perform some action
    {price, price_error} = validate_and_convert(price, "Price")
    {leasing_price, leasing_price_error} = validate_and_convert(leasing_price, "Leasing price")
    {extras, extras_error} = validate_and_convert(extras, "Extras")
    {car_tax, car_tax_error} = validate_and_convert(car_tax, "Car tax")
    {income, income_error} = validate_and_convert(income, "Income")

    model_year = case model_year do
      nil -> :invalid
      "" -> :invalid
      _ -> if Regex.match?(~r/^\d{4}$/, model_year), do: String.to_integer(model_year), else: :invalid
    end

    errors = Enum.filter([price_error, leasing_price_error, extras_error, car_tax_error, income_error], &(&1 != nil))

    errors = if model_year == :invalid do
      ["Model year must be in YYYY format" | errors]
    else
      errors
    end

    if errors != [] do
      {:noreply, assign(socket, error: errors)}
    else
      {monthly_cost, yearly_cost, monthly_cost_and_tax, yearly_cost_and_tax, monthly_tax, yearly_tax} = calculate_result(income, price, leasing_price, extras, model_year, fuel_type, car_tax)
      {:noreply, assign(socket,
        monthly_cost: monthly_cost,
        yearly_cost: yearly_cost,
        monthly_cost_and_tax: monthly_cost_and_tax,
        yearly_cost_and_tax: yearly_cost_and_tax,
        monthly_tax: monthly_tax,
        yearly_tax: yearly_tax,
        error: [])
      }
    end
  end

  defp validate_and_convert(value, field_name) do
    case value do
      nil -> {0, "#{field_name} cannot be empty"}
      "" -> {0, "#{field_name} cannot be empty"}
      _ -> {String.to_integer(value), nil}
    end
  end

  defp calculate_result(income, price, leasing_price, extras, _model_year, fuel_type, car_tax) do

    yearly_actual_price =
      case fuel_type do
        "plugin-hybrid" -> (price * 0.85)
        "electric" -> (price * 0.5)
        _ -> price
      end
      |> Kernel.+(extras)

    base_price_amount = 58800 * 0.29
    interest = yearly_actual_price *  ((0.0196 * 0.7) + 0.01)
    price_part = yearly_actual_price * 0.13

    leasing_price = leasing_price * 0.5

    yearly_cost = (base_price_amount + interest + price_part + car_tax)
    monthly_cost = (yearly_cost / 12)

    tax_limit = 53600
    monthly_income = income / 12

    monthly_tax =
      if monthly_income > tax_limit do
        monthly_cost * 0.5;
      else
        monthly_cost * 0.33;
      end

    monthly_cost_and_tax = monthly_cost + monthly_tax + leasing_price
    yearly_cost_and_tax = yearly_cost + (monthly_tax * 12) + (leasing_price * 12)

    {round(monthly_cost), round(yearly_cost), round(monthly_cost_and_tax), round(yearly_cost_and_tax), round(monthly_tax), round(monthly_tax * 12)}

  end
end
