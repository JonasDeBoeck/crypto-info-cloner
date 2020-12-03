defmodule Director.Repo.Migrations.AddDatabaseInteractionTables do
  use Ecto.Migration

  def change do
    DatabaseInteraction.Migrations.change()
  end
end
