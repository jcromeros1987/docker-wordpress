namespace :php do
  desc "Stop php-fpm"
  task :stop do
    on roles(:web) do
      execute "sudo service php5-fpm stop"
    end
  end

  desc "Start php-fpm"
  task :start do
    on roles(:web) do
      execute "sudo service php5-fpm start"
    end
  end

  desc "Restart php-fpm"
  task :restart do
    on roles(:web) do
      execute "sudo service php5-fpm restart"
    end
  end

  desc "Gracefully restart php-fpm"
  task :graceful do
    on roles(:web) do
      execute "test -r /var/run/php5-fpm.pid && sudo kill -s USR2 `cat /var/run/php5-fpm.pid`"
    end
  end
end
