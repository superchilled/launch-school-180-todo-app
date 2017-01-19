# session_persistence.rb

require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)

    tuple = result.first
    {id: tuple["id"], name: tuple["name"], todos: get_todos(tuple["id"])}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
      {id: tuple["id"], name: tuple["name"], todos: get_todos(tuple["id"])}
    end
  end

  def add_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def destroy_list(id)
    sql = "DELETE FROM lists WHERE id = $1;"
    query(sql, id)
  end

  def update_list_name(id, list_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, list_name, id)
  end

  def add_todo(list_id, name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, name, list_id)
  end

  def delete_todo(todo_id)
    sql = "DELETE FROM todos WHERE id = $1;"
    query(sql, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    status = new_status ? 't' : 'f'
    sql = "UPDATE todos SET status = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, status, todo_id, list_id)
  end

  def complete_all_todos(list_id)
    sql = "UPDATE todos SET status = 't' WHERE list_id = $1;"
    query(sql, list_id)
  end

  private

  def get_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)

    result.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["status"] == "t"}
    end
  end
end