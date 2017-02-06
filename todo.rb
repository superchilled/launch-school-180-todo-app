require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require_relative "session_persistence"
require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
  also_reload "session_persistence.rb"
end

helpers do
  def list_complete?(list)
    list[:todos_count] > 0 && list[:todos_remaining_count] == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

def load_list(id)
  list = @db_storage.find_list(id)
  return list if list

  error_message = "The specified list was not found."
  @session_storage.update_error(error_message)
  redirect "/lists"
  halt
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @db_storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

before do
  @session_storage = SessionPersistence.new(session)
  @db_storage = DatabasePersistence.new(logger)
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = @db_storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
  @session_storage.update_error(error)
    erb :new_list, layout: :layout
  else
    @db_storage.add_list(list_name)
    success_message = "The list has been created."
    @session_storage.update_success(success_message)
    redirect "/lists"
  end
end

# View a single todo list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  @todos = @db_storage.get_todos(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    @session_storage.update_error(error)
    erb :edit_list, layout: :layout
  else
    @db_storage.update_list_name(id, list_name)
    success_message = "The list has been updated."
    @session_storage.update_success(success_message)
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  @db_storage.destroy_list(id)
  success_message = "The list has been deleted."
  @session_storage.update_success(success_message)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    @session_storage.update_error(error)
    erb :list, layout: :layout
  else
    @db_storage.add_todo(@list_id, text)

    success_message = "The todo was added."
    @session_storage.update_success(success_message)
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @db_storage.delete_todo(todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    success_message = "The todo has been deleted."
    @session_storage.update_success(success_message)
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @db_storage.update_todo_status(@list_id, todo_id, is_completed)

  success_message = "The todo has been updated."
  @session_storage.update_success(success_message)
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @db_storage.complete_all_todos(@list_id)

  success_message = "All todos have been completed."
  @session_storage.update_success(success_message)
  redirect "/lists/#{@list_id}"
end
