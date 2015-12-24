namespace :deploy do
  desc "Create repo on Github"
  task :create_github_repo => :environment do

    login      = ENV["github_login"]
    pass       = ENV["github_pass"]
    repo_name  = ENV["repo_name"]

    Octokit.configure do |c|
      c.login = login
      c.password = pass
    end

    repo = Octokit.create_repository(repo_name)
    puts repo.clone_url
  end
end
