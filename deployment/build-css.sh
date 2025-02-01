#!/usr/bin/env bash

cd /var/www/html/wp-content/themes/wishpond


echo "Building style.css"
sass style.scss > style.css
sass style-2019.scss > style-2019.css
sass style-2021.scss > style-2021.css

if [ "$1" == "watch" ]; then
  echo "Watching for scss changes..."
  sass --watch style-2019.scss:style-2019.css
  sass --watch style-2021.scss:style-2021.css
fi
