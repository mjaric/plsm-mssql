defmodule Plsm.Database.MsSql do
  defstruct server: "localhost", port: "1433", username: "sa", password: "some!Password", database_name: "db", connection: nil
end

defimpl Plsm.Database, for: Plsm.Database.MsSql do
  
  @spec create(Plsm.Database.MsSql, Plsm.Configs) :: Plsm.Database.MsSql
  def create(_db, configs) do
    %Plsm.Database.MsSql{
      server: configs.database.server,
      port: configs.database.port,
      username: configs.database.username,
      password: configs.database.password,
      database_name: configs.database.database_name
    }
  end

  @spec connect(Plsm.Database.MsSql) :: Plsm.Database.MsSql
  def connect(db) do
    {_, conn} = Tds.start_link(
      hostname: db.server,
      username: db.username,
      port: db.port,
      password: db.password,
      database: db.database_name
    )

    %Plsm.Database.MsSql {
      connection: conn,
      server: db.server,
      port: db.port,
      username: db.username,
      password: db.password,
      database_name: db.database_name,
    }
  end

  # pass in a database and then get the tables using the Tds query then turn the rows into a table
  @spec get_tables(Plsm.Database.MsSql) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, result} = Tds.query(db.connection, "SELECT * FROM sys.tables WHERE [name] NOT IN ('schema_migrations')", [])
      result.rows
        |> List.flatten
        |> Enum.map(& %Plsm.Database.TableHeader {database: db, name: &1})
  end
 
  @spec get_columns(Plsm.Database.MsSql, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    query = """
    SELECT 
        col.column_id AS num
      , col.name AS column_name
      , typ.name AS data_type
      , xd.primary_key
      , CAST(NULL AS varchar(200)) AS foreign_table
      , CAST(NULL AS varchar(200)) AS foreign_field
    FROM sys.columns AS col
        INNER JOIN sys.types typ ON  col.system_type_id = typ.system_type_id 
                                AND col.user_type_id = col.user_type_id
        LEFT JOIN  (
          SELECT 
            ix.object_id, ixc.column_id, CASE ix.is_primary_key WHEN 1 THEN 1 ELSE 0 END AS primary_key
          FROM sys.indexes AS ix 
              INNER JOIN sys.index_columns AS ixc ON  ix.object_id = ixc.object_id 
                                              AND ix.index_id = ixc.index_id
        ) AS xd ON  col.object_id = xd.object_id 
                AND col.column_id = xd.column_id 
    WHERE col.object_id = OBJECT_ID(@table_name, 'U')
    ORDER BY 1 ASC
    """
    {_, result} = Tds.query(db.connection, query, [%Tds.Parameter{name: "table_name", value: table.name}])
    result.rows
    |> Enum.map(&to_column/1)
  end


  defp to_column(row) do
    {_,name} = Enum.fetch(row, 0)
    type = Enum.fetch(row, 1) |> get_type
    {_, foreign_table} = Enum.fetch(row, 3)
    {_, foreign_field} = Enum.fetch(row, 4)
    {_, is_pk} = Enum.fetch(row, 2)

    %Plsm.Database.Column{
      name: name,
      type: type,
      primary_key: is_pk,
      foreign_table: foreign_table,
      foreign_field: foreign_field
    }
  end

  defp get_type(start_type) do
    {_,type} = start_type
    upcase = String.upcase type
      cond do
        String.starts_with?(upcase, "INTEGER") == true -> :integer
        String.starts_with?(upcase, "INT") == true -> :integer
        String.starts_with?(upcase, "BIGINT") == true -> :integer
        String.starts_with?(upcase, "NVARCHAR") == true -> :string
        String.starts_with?(upcase, "VARCHAR") == true -> :string
        String.contains?(upcase, "CHAR") == true -> :text
        String.starts_with?(upcase, "TEXT") == true -> :text
        String.starts_with?(upcase, "FLOAT") == true -> :float
        String.starts_with?(upcase, "DOUBLE") == true -> :float
        String.starts_with?(upcase, "DECIMAL") == true -> :decimal
        String.starts_with?(upcase, "NUMERIC") == true -> :decimal
        String.starts_with?(upcase, "DATE") == true -> :date
        String.starts_with?(upcase, "DATETIME") == true -> :datetime
        String.starts_with?(upcase, "BIT") == true -> :boolean
        true -> :change_me
    end
  end
end