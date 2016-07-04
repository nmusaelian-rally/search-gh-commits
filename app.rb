require 'sinatra'
require 'shotgun'
require 'github_inator'
require 'time'


REPO_COMMITS_ENDPOINT = "repos/<org_name>/<repo_name>/commits"
SEARCH_REPOS_ENDPOINT = "search/repositories"
INFLATED_COMMIT_ENDPOINT = "repos/<org_name>/<repo_name>/commits/<sha>"

def get_all_results(connector, method, endpoint, options={}, data=nil, extra_headers=nil)
  total_results = []
  response = connector.make_request(method, endpoint,options,data,extra_headers)
  total_results << response.body
  while response.next != nil do
    response = connector.make_request(:get, response.next)
    total_results << response.body
  end
  total_results
end

def get_commits(owner, repository, lookback)
    config       = YAML.load_file('./configs/github.yml')
    lookback = (Time.now - lookback.to_i * 3600).iso8601
    @connector = GithubInator::GithubConnector.new(config)
    @commits_data = []
    since = {since: lookback}
    if (repository != "all-repos")
      get_repo_commits(owner, repository, since)
    else
      repos_with_recent_commits = []
      criteria = "user:#{owner}+pushed:>#{lookback}"
      options = {q: criteria}
      results = get_all_results(@connector, :get, SEARCH_REPOS_ENDPOINT, options).flatten
      total_count = results.first["total_count"]
      if total_count
        results.each do |page|
          page["items"].each do |result|
            repos_with_recent_commits << {'name' => result["name"], 'org' => result["owner"]["login"]}
          end
        end
      end
      if !repos_with_recent_commits.empty?
        repos_with_recent_commits.each do |repo|
          get_repo_commits(repo['org'], repo['name'], since)
        end
      end
    end
    return @commits_data
end

def get_repo_commits(org, repo, since)
  replacements = {'<org_name>' => org, '<repo_name>' => repo}
  repo_commits_endpoint = REPO_COMMITS_ENDPOINT.gsub(/<\w+>/) {|match| replacements.fetch(match,match)}
  commit_results = get_all_results(@connector, :get, repo_commits_endpoint, since).flatten
  commit_results.each do |result|
    replacements = {'<org_name>' => org, '<repo_name>' => repo, '<sha>' => result['sha']}
    inflated_commit_endpoint = INFLATED_COMMIT_ENDPOINT.gsub(/<\w+>/) {|match| replacements.fetch(match,match)}
    inflated_commits = get_all_results(@connector, :get, inflated_commit_endpoint).flatten
    files = []
    commit = {}
    commit['repo'] = repo
    inflated_commits.each do |inflated_result|
      if(!inflated_result['files'].empty?)
        inflated_result['files'].each do |file|
          files << file['filename']
        end
      end
      commit['sha'] = inflated_result['sha']
      commit['author'] = inflated_result['commit']['author']['name']
      commit['date']   = inflated_result['commit']['author']['date']
      commit['files'] = files
      commit['message'] = inflated_result['commit']['message']
      @commits_data << commit
    end
  end
end

get '/' do
  "Hello"
end

get '/search' do
  erb :search
end

post '/search' do
  if params[:repository].empty?
    params[:repository] = 'all-repos'
  end
  
  redirect "/results/#{params[:owner]}/#{params[:repository]}/#{params[:lookback]}"
end

get '/results/:owner/:repository/:lookback' do
  commits_data = get_commits(params[:owner], params[:repository], params[:lookback])
  erb :results, :locals => {:commits => commits_data, :owner => params[:owner], :lookback => params[:lookback]}
end