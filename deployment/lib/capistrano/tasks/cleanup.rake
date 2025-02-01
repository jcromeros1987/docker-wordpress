namespace :cleanup do
  desc "Cleanup old Autoptimize assets"
  task :autoptimize do
    on roles(:web) do
      # Delete assets older than a month
      execute "sudo find #{release_path}/wp-content/cache/autoptimize -mtime +31 -exec rm -v {} \\;"
    end
  end
end
