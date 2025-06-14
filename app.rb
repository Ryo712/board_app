require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'

enable :sessions

client = PG::connect(
  :host => "localhost",
  :dbname => "board")

get '/posts' do
  if session[:user].nil?
    return redirect '/login'
  end
  
  @posts = client.exec_params("SELECT * from posts").to_a
  erb :posts
end

post '/posts' do
  name = params[:name]
  content = params[:content]

  image_path = ''
  if !params[:img].nil? # データがあれば処理を続行する
    tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
    save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
    FileUtils.mv(tempfile, save_to)
    image_path = params[:img][:filename]
  end

  client.exec_params(
    "INSERT INTO posts (name, content, image_path) VALUES ($1, $2, $3)",
    [name, content, image_path]
  )

  redirect '/posts'
end

get '/signup' do
  erb :signup
end

post '/signup' do
  name = params[:name]
  email = params[:email]
  password = params[:password]

  client.exec_params(
    "INSERT INTO users (name, email, password) VALUES ($1, $2, $3)",
    [name, email, password]
  )

  redirect '/login'
end

get '/login' do
  erb :login
end

post '/login' do
  email = params[:email]
  password = params[:password]

  user = client.exec_params(
    "SELECT * FROM users WHERE email = $1 AND password = $2 LIMIT 1",
    [email, password]
  ).to_a.first

  if user.nil?
    return erb :login
  end

  session[:user] = user
  redirect '/posts'
end

delete '/logout' do
  session[:user] = nil
  redirect '/login'
end
