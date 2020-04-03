defmodule Storage do
	use Agent

	def start_link() do
		Agent.start_link(fn -> [] end, name: :storage)
	end

        def add(data) do
                Agent.update(:storage, fn l -> [data] ++ l end)
        end

	def pop() do
		{ret, l} = Agent.get(:storage, fn l -> List.pop_at(l, 0) end)
		Agent.update(:storage, fn _ -> l end)
		ret
	end
end # module

defmodule Reader do
	def read(path) do
		File.stream!(path)
		|> Enum.each(fn x -> to_string x |> String.trim() |> Storage.add() end)
	end 
end # module

defmodule Downloader do
	def download(url, dir) do
		'youtube-dl #{url} -o "#{Path.join(dir, "%(uploader)s-%(title)s.%(ext)s")}" --extract-audio --audio-format mp3'
		|> :os.cmd()
		IO.puts("Downloaded #{url}")
	end
end # module

## Main ##
{[dir: dir, input: input], _, _} = OptionParser.parse(System.argv(), strict: [dir: :string, input: :string])

Storage.start_link()
Reader.read(input)
create_downloaders = fn (f, t) ->
	case Storage.pop do
		nil -> t

		x ->
			task = Task.async(fn -> Downloader.download(x, dir) end)	
			f.(f, [task] ++ t)
	end
end
create_downloaders.(create_downloaders, [])
|> Enum.map(&Task.await(&1, :infinity))
