defmodule Database do
  require Tds

  def start_link do
    Tds.start_link(Application.get_env(:message_broker, :tds_conn))
  end


  def post(body,pid) do
    Tds.query!(pid, "INSERT INTO messages (name, msg ) VALUES (@name, @msg)",
        [
        %Tds.Parameter{name: "@name", value: Map.get(body,"user")}, %Tds.Parameter{name: "@msg", value: Map.get(body,"msg")}
        ])
  end

  def delete(name,pid) do
    Tds.query!(pid, "DELETE FROM messages WHERE name = '#{name}';",
        [])
  end

  def toMap(a) do
    {user, msg } = List.to_tuple(a)
    %{  "user" => user,  "msg" => msg }
  end

end
