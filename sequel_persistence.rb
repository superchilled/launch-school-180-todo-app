# session_persistence.rb

require "sequel"

DB = Sequel.connect("postgres://karl:nikita@localhost/todos")

class SequelPersistence
  def initialize(logger)
    DB.logger = logger
  end

  def find_list(id)
    all_lists.first(:lists__id=>id)
  end

  def all_lists
    DB[:lists].left_join(:todos, :list_id=>:id).
    select_all(:lists).
    select_append do
      [count(todos__id).as(todos_count),
       count(nullif(todos__status, true)).as(todos_remaining_count)]
    end.group(:lists__id).
    order(:lists__name)
  end

  def add_list(list_name)
    DB[:lists].insert(:name=>list_name)
  end

  def destroy_list(id)
    DB[:lists].where(:id=>id).delete
  end

  def update_list_name(id, list_name)
    DB[:lists].where(:id=>id).update(:name=>list_name)
  end

  def add_todo(list_id, name)
    DB[:todos].insert(:name=>name, :list_id=>list_id)
  end

  def delete_todo(list_id, todo_id)
    DB[:todos].where(:list_id=>list_id, :id=>todo_id).delete
  end

  def update_todo_status(list_id, todo_id, new_status)
    status = new_status ? true : false
    DB[:todos].where(:list_id=>list_id, :id=>todo_id).update(:status=>status)
  end

  def complete_all_todos(list_id)
    get_todos(list_id).update(:status=>true)
  end

  def get_todos(list_id)
    DB[:todos].where(:list_id=>list_id)
  end
end