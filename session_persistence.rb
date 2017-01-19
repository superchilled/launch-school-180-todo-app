# session_persistence.rb

class SessionPersistence

  def initialize(session)
    @session = session
    @session[:error] ||= nil
    @session[:success] ||= nil
  end

  def update_error(msg)
    @session[:error] = msg
  end

  def update_success(msg)
    @session[:success] = msg
  end
end