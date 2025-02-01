namespace :nginx do
  desc "Stop nginx"
  task :stop do
    on roles(:web) do
      execute "sudo service nginx stop"
    end
  end

  desc "Start nginx"
  task :start do
    on roles(:web) do
      execute "sudo service nginx start"
    end
  end

  desc "Restart nginx"
  task :restart do
    on roles(:web) do
      execute "sudo nginx -t && sudo service nginx restart"
    end
  end

  desc "Gracefully restart nginx"
  task :graceful do
    on roles(:web) do
      execute "sudo nginx -t && sudo service nginx reload"
    end
  end

  desc "Check nginx config"
  task :check do
    on roles(:web) do
      execute "sudo nginx -t"
    end
  end

  desc "Purge the nginx page cache (destructive)"
  task :purge do
    on roles(:web) do
      execute "sudo #{release_path}/lib/capistrano/tasks/nginx_cache_purge * /var/run/nginx-cache/"
    end
  end

  # desc "Remove Nginx upstart config files (destructive)"
  # task :purge_upstart do
  #   on roles(:web) do
  #     execute "sudo initctl stop nginx && sudo rm /etc/init/nginx.conf"
  #     execute "sudo update-rc.d nginx defaults && sudo service nginx reload"
  #   end
  # end
end
