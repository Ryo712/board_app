require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'

enable :sessions

client = PG::connect(
  :host => "localhost",
  :dbname => "board")

get '/posts' do
  if session[:user].nil? #ユーザーが登録されてなければ/loginにリダイレクト
    return redirect '/login' 
  end
  
  @posts = client.exec_params("SELECT * from posts").to_a #postsから全ての投稿を取得。.to_aで結果を配列に変換
  erb :posts #posts.erbを表示
end

post '/posts' do
  name = params[:name] #投稿者名
  content = params[:content] #投稿内容(textareaで入力された投稿内容)

  image_path = '' #DBに投稿を保存
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

  redirect '/posts' #一覧ページにリダイレクト
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
  erb :login #login.erbを表示
end

post '/login' do
  email = params[:email]
  password = params[:password]

  user = client.exec_params( #WHERE句でemail AND passwordの完全一致を検索
    "SELECT * FROM users WHERE email = $1 AND password = $2 LIMIT 1",
    [email, password]
  ).to_a.first

  if user.nil?
    return erb :login #ログイン失敗時(ユーザーがいない)場合login.erbにリダイレクト
  end

  session[:user] = user #ユーザー情報をセッションに保存
  redirect '/posts'
end

delete '/logout' do 
  session[:user] = nil #セッションからユーザー情報を削除
  redirect '/login' #ログインページにリダイレクト
end
