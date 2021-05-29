defmodule Metapede.Repo.Migrations.CreateTopic do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :description, :string
      timestamps()
    end
  end
end
