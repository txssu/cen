list_difference = fn list1, list2 ->
  eq_count_1 = Enum.count(list1, &Enum.member?(list2, &1))
  eq_count_2 = Enum.count(list2, &Enum.member?(list1, &1))

  (eq_count_1 + eq_count_2) / (Enum.count(list1) + Enum.count(list2))
end

all_components =
  "lib/cen_web/**/*.{ex,heex}"
  |> Path.wildcard()
  |> Enum.flat_map(fn filename ->
    file = File.read!(filename)
    # Find all `class="..."` attributes
    ~r/class="(.*?)"/
    |> Regex.scan(file)
    |> Enum.map(&Enum.at(&1, 1))
  end)
  |> Enum.map(fn component ->
    String.split(component, " ")
  end)
  |> Enum.reject(&(length(&1) == 1))

pairs =
  Enum.flat_map(all_components, fn component ->
    Enum.map(all_components, fn another_component ->
      if length(component) > length(another_component) do
        {component, another_component}
      else
        {another_component, component}
      end
    end)
  end)

freqs =
  pairs
  |> Map.new(fn {comp1, comp2} = pair ->
    freq = Enum.count(all_components, fn comp -> comp == comp1 or comp == comp2 end)
    {pair, freq}
  end)
  |> Map.filter(fn {_pair, freq} -> freq > 2 end)

result =
  pairs
  |> Enum.filter(fn pair -> Map.has_key?(freqs, pair) end)
  |> Enum.uniq_by(fn {comp1, comp2} -> Enum.sort_by([comp1, comp2], &length/1) end)
  |> Enum.map(fn {comp1, comp2} = pair -> {comp1, comp2, list_difference.(comp1, comp2), freqs[pair]} end)
  |> Enum.reject(fn {_comp1, _comp2, diff, _freq} -> diff == 1 or diff == 0 end)
  |> Enum.sort_by(&(elem(&1, 2) * elem(&1, 3)), :desc)
  |> Enum.map(fn {comp1, comp2, diff, freq} ->
    [classes1, classes2] = Enum.sort_by([comp1, comp2], &Enum.count(&1), :desc)

    difference = List.myers_difference(classes1, classes2)

    [
      "Component 1: #{Enum.join(comp1, " ")}\n",
      "Component 2: #{Enum.join(comp2, " ")}\n",
      "Difference rate: #{diff}\n",
      "Difference: #{inspect(difference, pretty: true)}\n",
      "Frequency: #{freq}\n",
      "-----\n"
    ]
  end)

File.write!("priv/scripts/tailwind_components_diffs.txt", result)
