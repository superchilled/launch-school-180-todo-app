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
    sql = <<~SQL
      SELECT lists.*,
        count(todos.id) AS todos_count,
        count(NULLIF(status, true)) AS todos_remaining_count
        FROM lists
        LEFT JOIN todos ON lists.id = todos.list_id
        WHERE lists.id = $1
        GROUP BY lists.id
        ORDER BY lists.name;
    SQL
    result = query(sql, id)

    tuple_to_list_hash(result.first)
  end

  def all_lists
    sql = <<~SQL
      SELECT lists.*,
        count(todos.id) AS todos_count,
        count(NULLIF(status, true)) AS todos_remaining_count
        FROM lists
        LEFT JOIN todos ON lists.id = todos.list_id
        GROUP BY lists.id
        ORDER BY lists.name;
    SQL
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
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

  def get_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)

    result.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["status"] == "t"}
    end
  end

  private

  def tuple_to_list_hash(tuple)
    {
      id: tuple["id"],
      name: tuple["name"],
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i
    }
  end
end